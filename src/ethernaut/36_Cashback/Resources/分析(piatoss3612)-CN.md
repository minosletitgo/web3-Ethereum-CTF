# EIP-7702 Set Code For EOAs（EOA代码设置功能）

#### **开始之前...**

建议先简要了解以太坊的账户抽象化概念，这将有助于理解本文内容。

[2024.04.22 - \[区块链/Ethereum\] - ERC-4337: 账户抽象化 - 简要整理](https://piatoss3612.tistory.com/167)

___

## **登场背景**

EIP-7702是5月初以太坊Pectra升级中包含的升级规范之一，流传着维塔利克·布特林（Vitalik Buterin）仅用20分钟就完成初稿的传说。虽然维塔利克确实头脑出众，但一个生态系统的领导者如此仓促地撰写初稿，背后可能隐藏着不为人知的紧张背景。事实上，EIP-3074和ERC-4337两大阵营之间曾发生过激烈的论战。

虽然EIP-3074已是被废弃的提案，且我对其背景信息掌握有限，但仍简要说明如下：

- 向EVM新增AUTH、AUTHCALL两种新操作码（opcode）
- EOA可通过该操作码向名为invoker的智能合约授予权限
- invoker利用从EOA获得的权限，处理智能合约级别的各类需求

可以说，**基于EOA的功能扩展**是EIP-3074的核心目标。

虽然其初衷可以理解，但基于EOA的功能扩展与以太坊生态系统中**账户抽象化、ERC-4337所指明的方向——EOA向智能账户的完全转型**——存在显著分歧。维塔利克自然无法坐视不理，因为ERC-4337本身就体现了他的核心愿景。此外，向虚拟机新增操作码可能引发不可预知的副作用，因此需要经过漫长的测试周期。

正因如此，维塔利克提笔疾书，以专注状态撰写了EIP-7702初稿，力求让两大阵营都能接受。

___

## **EIP-7702 核心概念**

EIP-7702**引入了一种为EOA设置“代码”的新交易类型**。此前仅有智能合约可以包含代码，而现在EOA也能拥有代码。通过这一机制，EOA可将特定地址的代码委托（delegation）给自己，并基于此在智能合约层面实现批量操作、赞助支付、权限限制等多种功能。

下面逐一解析核心概念：

### **1. 新交易类型**

新增了名为**SetCodeTxType（0x04）** 的交易类型。

```go
// 交易类型定义
const (
LegacyTxType     = 0x00  // 传统交易类型
AccessListTxType = 0x01  // 访问列表交易类型
DynamicFeeTxType = 0x02  // 动态费率交易类型（EIP-1559）
BlobTxType       = 0x03  // Blob交易类型
SetCodeTxType    = 0x04  // EIP-7702代码设置交易类型
)
```

该交易类型与EIP-1559动态费率交易共享相同的基础字段，同时新增了**AuthList（授权列表，authorization_list）** 字段。此新增字段不可为空，因为执行EIP-7702交易（0x04类型）必须明确包含“为EOA设置或移除代码”的意图。

```go
// SetCodeTx 实现EIP-7702交易类型，用于在签名者地址临时部署代码
type SetCodeTx struct {
ChainID    *uint256.Int       // 链ID
Nonce      uint64             // 交易nonce
GasTipCap  *uint256.Int       // 最大优先费率（maxPriorityFeePerGas）
GasFeeCap  *uint256.Int       // 最大费率上限（maxFeePerGas）
Gas        uint64             // 燃气限制
To         common.Address     // 接收地址（可为空）
Value      *uint256.Int       // 转账金额
Data       []byte             // 交易数据
AccessList AccessList         // 访问列表
AuthList   []SetCodeAuthorization  // 授权列表（EIP-7702新增）

// 签名相关字段
V *uint256.Int  // y坐标奇偶性
R *uint256.Int  // 签名R值
S *uint256.Int  // 签名S值
}
```

<img src="./images/piatoss3612_eip7702_type04.png" alt="" width="750">

> 💡 注意：强制采用动态费率交易结构，因此传统交易类型中使用的gasPrice字段不再支持。

### **2. 授权列表（Authorization List）**

授权列表由**一个或多个授权元组（Authorization Tuple）** 组成。

```go
// SetCodeAuthorization 表示账户授权在其地址部署代码的结构体
type SetCodeAuthorization struct {
ChainID uint256.Int    `json:"chainId" gencodec:"required"`  // 链ID
Address common.Address `json:"address" gencodec:"required"`  // 授权委托地址
Nonce   uint64         `json:"nonce" gencodec:"required"`    // EOA账户nonce
V       uint8          `json:"yParity" gencodec:"required"`  // 签名y坐标奇偶性
R       uint256.Int    `json:"r" gencodec:"required"`        // 签名R值
S       uint256.Int    `json:"s" gencodec:"required"`        // 签名S值
}
```

#### **2-1. 授权元组的构成**

每个授权元组包含以下字段：

- **chain_id**：0或EIP-7702交易执行所在链的ID
- **address**：持有要为EOA设置代码的**委托目标地址（智能合约地址）**
- **nonce**：应用代码设置的EOA账户当前nonce
- **v, r, s**：针对授权元组上下文的有效签名值

> 💡 注意：若chain_id设为0，同一签名可能在所有支持EIP-7702的链上有效，从而引发重放攻击风险。

#### **2-2. 授权元组的构建方法**

假设DORO希望在以太坊主网（chain_id=1）将Alchemy的Semi Modular Account 7702合约代码设置到自己的EOA中，且该EOA从未执行过任何交易（初始状态）。关于nonce的作用及为何需设为1，将在第3节详细说明。

构建授权元组需准备以下参数：
- chain_id：1（以太坊主网）
- address：0x69007702764179f14F51cdce752f4f775d74E139（委托目标合约地址）
- nonce：1

<img src="./images/piatoss3612_eip7702_chainid.png" alt="" width="750">

将上述参数与作为域分隔符的0x05前缀一起进行RLP序列化，再通过keccak256哈希函数生成签名哈希（sigHash）：

> keccack256(rlp(0x05, chain_id, address, nonce)) = sigHash（签名哈希）

随后DORO使用EOA的私钥对签名哈希进行签名，生成签名值（r, s, v）。

<img src="./images/piatoss3612_eip7702_sigHash.png" alt="" width="750">

将签名值（r, s, v）与之前准备的chain_id、address、nonce组合为完整授权元组`[chain_id, address, nonce, v, r, s]`，并将该元组添加到授权列表中，即可完成EIP-7702交易的准备工作。

> 💡 若需移除EOA中已设置的代码，需将address设为零地址（0x0000...0000）构建元组，并执行EIP-7702交易。

**▼ 从geth代码看授权列表构建逻辑**

### **3. Nonce处理机制**

传统交易仅需在交易字段中包含EOA的nonce，而EIP-7702交易要求授权元组中也必须包含EOA的nonce。因此需明确nonce的验证顺序和递增规则。更复杂的是，**只要授权元组有效，第三方即可代为构建授权列表并执行EIP-7702交易**。下面先介绍常规的nonce递增逻辑，再通过具体示例说明第三方代执行流程。

#### **3-1. Nonce递增顺序**

常规nonce递增流程如下：

1. 交易执行时，首先验证发送者（sender）的当前nonce与交易字段中声明的nonce是否一致；若一致，将发送者的nonce递增1（交易级nonce处理优先）。
2. 随后对授权列表中的每个授权元组执行以下验证逻辑：
    1. 使用元组中的（chain_id, address, nonce）参数重构签名哈希（sigHash），并通过ecrecover函数结合签名值（r, s, v）恢复签名者地址（authority）。
    2. 验证签名者（authority）的当前nonce与授权元组中声明的nonce是否一致；若一致，将该账户的nonce递增1。
    3. 验证通过后，为EOA附加或移除代码。**此时附加的代码称为“委托指定者”**，具体将在第4节说明。

<img src="./images/piatoss3612_eip7702_txPic.png" alt="" width="750">

综上，交易字段中的nonce优先处理，授权列表中的各元组nonce按顺序依次处理。由于顺序严格固定，目前无法实现“为EOA设置代码→执行交易→移除代码”等复杂流程。此外，即使一个EOA通过多个授权元组多次设置代码，最终仅最后一个验证通过的元组所指向的地址代码会被保留在EOA中。

> 💡 注意：授权列表验证过程中，部分元组验证失败不会影响其他元组的验证结果——仅验证通过的元组会生效，失败的元组将被作废。

#### **3-2. 场景1：DORO直接执行EIP-7702交易**

1.  **初始状态设置**
    - 假设DORO的EOA当前nonce为0。
    - 授权列表中包含1个用于为DORO的EOA设置代码的元组（nonce设为1）。
2.  **交易验证及处理**
    - 客户端首先验证交易中声明的nonce（0）与DORO的实际nonce是否一致。
    - 验证通过后，DORO的EOA nonce从0递增至1。
3.  **授权列表处理**
    - 接着对交易中包含的授权列表内各授权元组进行验证。
    - 每个授权元组需满足：当前DORO的EOA nonce（1）与元组中声明的nonce一致。
    - 验证通过后，DORO的EOA nonce从1递增至2，同时委托指定者被设置到EOA中。
4.  **执行结果**
    - EIP-7702交易执行完成后，DORO的EOA nonce变为2，委托指定者成功部署到EOA中。

#### **3-3. 场景2：DORO委托管理员代执行EIP-7702交易**

1.  **初始状态**
    - 假设DORO的EOA当前nonce为2。
    - 假设管理员的EOA当前nonce为7。
    - DORO已构建完成授权元组（nonce设为2）并传递给管理员。
    - 管理员将DORO的授权元组加入授权列表，发起EIP-7702交易。
2.  **交易验证及处理**
    - 客户端验证交易中声明的nonce（7）与管理员的实际nonce是否一致。
    - 验证通过后，管理员的EOA nonce从7递增至8。
3.  **授权列表处理**
    - 随后对授权列表中的各授权元组进行验证。
    - DORO的授权元组需满足：元组中声明的nonce（2）与DORO的当前EOA nonce（2）一致。
    - 验证通过后，DORO的EOA nonce从2递增至3。
    - 若列表中还包含HONG的授权元组，则对HONG的EOA nonce执行相同验证流程。
4.  **执行结果**
    - 管理员提交的交易因nonce匹配成功执行，管理员的EOA nonce从7变为8。
    - 交易中包含的DORO授权元组验证通过，DORO的EOA nonce从2变为3。
    - 若HONG的授权元组也被处理，则HONG的EOA nonce相应递增。

#### **3-4. 新nonce递增逻辑的影响总结**

| **影响维度**         | **详细说明**                                                                                                                                                                                                 |
|----------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 交易与授权分离       | 授权元组创建者（EOA）与EIP-7702交易发送者可为不同账户，支持跨账户聚合授权元组并执行批量授权（batch authorization），实现手续费赞助等灵活交易模式。                                                             |
| 开发复杂度提升       | 新增的nonce机制增加了SDK或钱包服务开发过程中nonce管理的复杂度。                                                                                                                                               |
| 代理授权滥用风险     | 存在恶意攻击者聚合用户授权后，通过代理授权为用户EOA设置恶意智能合约，进而执行合约窃取用户资金的安全风险。                                                                                                       |

### **4. 委托指定（Delegation Designation）**

#### **4-1. 委托指定的定义**

委托指定是利用EIP-3541中曾被禁用的操作码0xef，标记特定代码具有特殊用途的机制。此处的“特殊用途”与通过EIP-7702交易部署到EOA的代码直接相关。

前文提到，经授权元组验证通过后附着到EOA的代码称为“委托指定者”。该委托指定者是一段23字节的代码，格式为前缀`0xef0100`与授权元组中声明的address拼接而成（即`0xef0100<address>`）。代码一旦部署到EOA，在被主动移除前将持续有效。

<img src="./images/piatoss3612_eip7702_author.png" alt="" width="750">

#### **4-2. 委托指定者的工作原理**

委托指定者在进入虚拟机执行上下文前，扮演“指针”角色：从指定地址（address）加载可执行代码并分配给EOA。因此，**CALL、CALLCODE、STATICCALL、DELEGATECALL等执行类指令将实际执行委托指定者指向地址的代码**。

与之相对，EXTCODESIZE、EXTCODECOPY、EXTCODEHASH等代码读取类指令仅作用于委托指定者本身（`0xef0100 || address`）。

- 若委托指定者指向预编译合约（precompile）地址，则加载的代码被视为空代码；在提供充足燃气的情况下，相关执行指令会执行空代码并返回成功。
- 若委托指定者形成链式指向（如A指向B、B指向C）或循环指向（指针的指针），客户端仅解析首个委托指定者对应的代码，不追溯后续指向链。

> 💡 更详细的验证过程将在后续文章中结合Foundry测试案例展开说明。

#### **4-3. 进入虚拟机执行上下文前的流程**

假设DORO发起一笔交易，调用已部署委托指定者代码的EOA，具体流程如下：

<img src="./images/piatoss3612_eip7702_05.png" alt="" width="750">

1.  交易验证阶段：以太坊客户端首先解析EOA中的委托指定者，提取目标address。
    <img src="./images/piatoss3612_eip7702_06.png" alt="" width="750">
2.  从状态数据库（state db）中加载该address对应的合约代码，并临时附着到EOA。
    <img src="./images/piatoss3612_eip7702_07.png" alt="" width="750">
3.  验证逻辑完成后进入EVM执行上下文：DORO实际调用的代码并非委托指定者本身，而是其指向address对应的合约代码。但需注意，代码的执行上下文仍为EOA（而非目标address）。例如：
    - 若将Uniswap V3 Router的代码附着到EOA，该代码无法访问Uniswap V3 Router原有的存储数据，仅能操作EOA自身的存储。
    - 核心原因：加载的代码仅为逻辑层，与原合约的存储层完全分离，仅关联EOA的存储空间。
      <img src="./images/piatoss3612_eip7702_08.png" alt="" width="750">

> 💡 部署到EOA的代码支持随时替换/修改，这一点与可升级智能合约（Upgradeable Smart Contract）有相似之处。由于逻辑层与存储层分离，需特别注意存储冲突问题。

___

## **总结**

| **核心项**                 | **概要说明**                                                                                                                                                                                                 | **重要要点 / 安全影响**                                                                 |
|----------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------|
| **新交易类型**             | SetCodeTxType（0x04）—— EIP-7702专用交易类型，沿用EIP-1559动态费率结构，新增AuthList字段                                                                                                                     | AuthList不可为空；不支持传统交易的gasPrice字段                                          |
| **授权列表（AuthList）**   | 由多个SetCodeAuthorization元组组成，至少需包含1个元组                                                                                                                                                        | 仅需元组有效，第三方（如中继者）即可代提交 → 存在代理执行/赞助攻击风险                  |
| **授权元组结构 & 签名**    | 结构：(chain_id, address, nonce, v, r, s)<br>签名哈希：sigHash = keccak256(rlp(0x05, chain_id, address, nonce))                                                                                               | chain_id=0时存在跨链重放风险；元组需通过EOA私钥签名验证                                |
| **nonce处理顺序**          | 1) 验证交易nonce → 递增发送者nonce<br>2) 按顺序验证授权元组：元组nonce与授权者当前nonce一致 → 递增授权者nonce                                                                                                 | 交易nonce优先处理；元组顺序影响执行结果；部分元组验证失败不影响其他元组生效             |
| **第三方中继（代提交）**   | 授权元组创建者（授权方）与交易发送者可分离，支持跨账户聚合元组提交                                                                                                                                             | 支持批量授权、手续费赞助，但增加恶意合约部署风险                                        |
| **委托指定者**             | EOA实际部署的代码：`0xef0100<address>`<br>作用：指向持有实际业务逻辑的合约地址的指针                                                                                                                         | -                                                                                     |
| **执行上下文 & 存储**      | 加载的代码在**EOA的执行上下文/存储空间**中运行，不引用原合约的存储数据                                                                                                                                         | 逻辑/存储分离支持代码替换，但需警惕存储冲突                                             |
| **代码移除**               | 构建address为零地址（0x000...0000）的授权元组，提交EIP-7702交易即可移除代码                                                                                                                                   | 代码移除操作同样需通过授权元组验证控制                                                |

___

## **向完全智能账户迁移的过渡阶段**

以上就是EIP-7702的核心概念解析。通过在EOA中部署ERC-4337智能账户的代码，既能保持与现有ERC-4337生态的兼容性，又能通过EOA自身的功能扩展满足EIP-3074阵营的需求，是一项非常巧妙的提案。不过，这究竟是EIP-3074阵营真正认可的妥协方案，还是被维塔利克的影响力“说服”后的沉默，仍有待商榷。

当前阶段可视为以太坊账户模型演进的关键过渡时期。即便现在通过EOA部署智能账户代码，用户仍需管理EOA私钥或智能账户专属的P256/BLS等签名密钥——EOA私钥依然拥有对账户的完全控制权。这反而可能导致攻击面扩大：EOA和智能账户双重密钥管理增加了私钥泄露的风险。

要实现向完全智能账户的迁移，协议层需要支持临时或永久作废与EOA绑定的私钥的方案。但现实挑战在于：多数用户习惯在以太坊、Cosmos、比特币等多个生态系统中复用同一私钥。用户是否愿意为智能账户单独管理新密钥，放弃跨生态私钥复用的便利性？维塔利克及其团队将如何解决这一矛盾，值得持续关注。

#### **相关EIP**

- [EIP-7377](https://eips.ethereum.org/EIPS/eip-7377)
- [EIP-7701](https://eips.ethereum.org/EIPS/eip-7701)
- [EIP-7851](https://eips.ethereum.org/EIPS/eip-7851)

___

## **结语**

本文是基于3月底为公司内部分享准备的资料优化后的版本。没想到理解一个标准需要涉及如此多复杂的细节……还有很多内容没来得及展开。现在回想起来，当时是怎么整理出这些资料的呢？这也难怪web3开发人才如此稀缺。

___

## **参考资料**

- [go-ethereum EIP-7702实现PR](https://github.com/ethereum/go-ethereum/pull/30078)
- [EIP-7702官方文档](https://eip.tools/eip/7702)
- [Safe Global: EIP-7702与以太坊Pectra升级中的智能账户](https://safe.global/blog/eip-7702-smart-accounts-ethereum-pectra-upgrade)
- [Colin Lyguo: EIP-7702技术解析](https://hackmd.io/@colinlyguo/SyAZWMmr1x)
