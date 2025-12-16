# Ethernaut Lvl 19 MagicNumber Walkthrough: How to deploy contracts using raw assembly opcodes | by Nicole Zhu | Coinmonks | Medium

This level requires some assembly programming to deploy a tiny contract to the EVM.

![](https://miro.medium.com/v2/resize:fit:2000/format:webp/1*5Wrb7z3W6AMtjH6IKJYowg.jpeg)

Let’s break this down :)

## What happens during contract creation

Recall that during [contract initialization](https://medium.com/coinmonks/ethernaut-lvl-14-gatekeeper-2-walkthrough-how-contracts-initialize-and-how-to-do-bitwise-ddac8ad4f0fd), the following happens:

1\. **First, a user or contract sends a transaction to the Ethereum network.** This transaction contains data, but no recipient address. This format indicates to the EVM that is a `contract creation`, not a regular send/call transaction.

2\. **Second, the EVM compiles the contract code in Solidity (a high level, human readable language) into bytecode (a low level, machine readable language).** This bytecode directly translates into opcodes, which are executed in a single call stack.

> Important to note: `contract creation` bytecode contains both 1)`initialization code` and 2) the contract’s actual `runtime code`, concatenated in sequential order.

3\. **During contract creation, the EVM only executes the** `**initialization code**` until it reaches the first STOP or RETURN instruction in the stack. During this stage, the contract’s constructor() function is run, and the contract has an address.

3.1. **After this initialization code is run, only the** `**runtime code**` **remains on the stack**. These opcodes are then copied into memory and returned to the EVM.

5\. **Finally, the EVM stores this returned, surplus code in the state storage,** in association with the new contract address. This is the `runtime code` that will be executed by the stack in all future calls to the new contract.

### Put simply

To solve this level, you need 2 sets of opcodes:

-   `Initialization opcodes`: to be run immediately by the EVM to create your contract and store your future runtime opcodes, and
-   `Runtime opcodes`: to contain the actual execution logic you want. This is the main part of your code that should **return 0x** `**0x42**` **and be under 10 opcodes.**

_At this point, to independently solve this level, you can read in depth about_ [_opcodes_](https://medium.com/@blockchain101/solidity-bytecode-and-opcode-basics-672e9b1a88c2) _and_ [_smart contract deconstruction_](https://blog.zeppelin.solutions/deconstructing-a-solidity-contract-part-i-introduction-832efd2d7737) _(from the author of this Ethernaut level)._

_For a bit more guidance, let’s press on…_

## Detailed Walkthrough

![](https://miro.medium.com/v2/resize:fit:1100/format:webp/1*3oSxbDxt1O5IYzW1vX7MmQ.png)

0\. Power up [truffle console with Ropsten](https://medium.com/coinmonks/5-minute-guide-to-deploying-smart-contracts-with-truffle-and-ropsten-b3e30d5ee1e) (or your preferred setup) to be able to directly deploy bytecode to the EVM. And open up this [bytecode <> opcode conversion](https://github.com/ethereum/pyethereum/blob/develop/ethereum/opcodes.py) chart for easy reference.

## Runtime Opcodes — Part 1

First, let’s figure out the `runtime code` logic. The level constrains you to only 10 opcodes. Luckily, it doesn’t take more than that to return a simple `0x42`.

**Returning values** is handled by the `RETURN` opcode, which takes in two arguments:

-   `p`: the position where your value is stored in memory, i.e. 0x0, 0x40, 0x50 (see figure). _Let’s arbitrarily pick the 0x80 slot._
-   `s`: the size of your stored data. _Recall your value is 32 bytes long (or 0x20 in hex)._

_Recall that Ethereum memory looks like this, with 0x0, 0x10, 0x20… as the official position references:_

![](https://miro.medium.com/v2/resize:fit:640/format:webp/1*gkbvs_Csc4SusEMNegXcNQ.png)

Every Ethereum transaction has 2²⁵⁶ bytes of (temporary) memory space to work with

But… this means before you can return a value, first you have to store it in memory.

1.  First, store your `0x42` value in memory with `mstore(p, v)`, where p is position and v is the value in hexadecimal:

```shell
6042    // v: push1 0x42 (value is 0x42)
6080    // p: push1 0x80 (memory slot is 0x80)
52      // mstore
```

2\. Then, you can `return` this the `0x42` value:

```shell
6020    // s: push1 0x20 (value is 32 bytes in size)
6080    // p: push1 0x80 (value was stored in slot 0x80)
f3      // return
```

This resulting opcode sequence should be `604260805260206080f3`. Your runtime opcode is exactly 10 opcodes and 10 bytes long.

## Initialization Opcodes — Part 2

Now let’s create the contract `initialization opcodes`. These opcodes need to replicate your `runtime opcodes` to memory, before returning them to the EVM. _Recall that the EVM will then automatically save the runtime sequence_ `_604260805260206080f3_` _to the blockchain — you won’t have to handle this last part._

**Copying code** from one place to another is handled by the opcode `codecopy`, which takes in 3 arguments:

-   `t`: the destination position of the code, in memory. _Let’s arbitrarily save the code to the 0x00 position._
-   `f`: the current position of the `runtime opcodes`, in reference to the entire bytecode. Remember that `f` starts after `initialization opcodes` end. _What a chicken and egg problem! This value is currently unknown to you._
-   `s`: size of the code, in bytes. _Recall that_ `_604260805260206080f3_` _is 10 bytes long (or 0x0a in hex)._

3\. First copy your `runtime opcodes` into memory. Add a placeholder for `f`, as it is currently unknown:

```shell
600a    // s: push1 0x0a (10 bytes)
60??    // f: push1 0x?? (current position of runtime opcodes)
6000    // t: push1 0x00 (destination memory index 0)
39      // CODECOPY
```

4\. Then, `return` your in-memory `runtime opcodes` to the EVM:

```shell
600a    // s: push1 0x0a (runtime opcode length)
6000    // p: push1 0x00 (access memory index 0)
f3      // return to EVM
```

5\. Notice that in total, your `initialization opcodes` take up 12 bytes, or `0x0c` spaces. This means your `runtime opcodes` will start at index `0x0c`, where `f` is now known to be `0x0c`:

```shell
600a    // s: push1 0x0a (10 bytes)
600c    // f: push1 0x?? (current position of runtime opcodes)
6000    // t: push1 0x00 (destination memory index 0)
39      // CODECOPY
```

6\. The final sequence is thus:

```shell
0x600a600c600039600a6000f3604260805260206080f3
```

Where the first 12 bytes are `initialization opcodes` and the subsequent 10 bytes are your `runtime opcodes`.

7\. In Truffle console, create your contract with the following commands:

```shell
> var account = "your address here";
> var bytecode = "0x600a600c600039600a6000f3604260805260206080f3";
> web3.eth.sendTransaction({ from: account, data: bytecode }, function(err,res){console.log(res)});
```

8\. Look up the newly created **contract address** from the returned transaction hash. You can do this via Etherscan or via getTransactionReceipt(hash)**.**

9\. In the Ethernaut web console, simply input the following to pass the level:

```javascript
await contract.setSolver("contract address");
```
