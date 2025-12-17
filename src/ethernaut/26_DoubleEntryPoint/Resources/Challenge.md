<img src="image.png" alt="" width="750">

### DoubleEntryPoint
* Difficulty：★★☆☆☆
* This level features a CryptoVault with special functionality, the sweepToken function. 
* This is a common function used to retrieve tokens stuck in a contract. 
* The CryptoVault operates with an underlying token that can't be swept, as it is an important core logic component of the CryptoVault. Any other tokens can be swept.
* The underlying token is an instance of the DET token implemented in the DoubleEntryPoint contract definition and the CryptoVault holds 100 units of it. 
* Additionally the CryptoVault also holds 100 of LegacyToken LGT.
* In this level you should figure out where the bug is in CryptoVault and protect it from being drained out of tokens.
* The contract features a Forta contract where any user can register its own detection bot contract. 
* Forta is a decentralized, community-based monitoring network to detect threats and anomalies on DeFi, NFT, governance, bridges and other Web3 systems as quickly as possible. 
* Your job is to implement a detection bot and register it in the Forta contract. 
* The bot's implementation will need to raise correct alerts to prevent potential attacks or bug exploits.

---------------------------------------------------------------------------------------------------------

### 双重入口点
* 难度：★★☆☆☆
* 本关卡包含一个具有特殊功能的 CryptoVault 合约，核心功能为 `sweepToken` 函数。
* 该函数是用于取回合约中滞留代币的常见功能。
* CryptoVault 合约依赖一种底层代币（underlying token），该代币不可被清扫（sweep），因其是 CryptoVault 核心逻辑的重要组成部分。其他任何代币均可被清扫。
* 底层代币是 `DoubleEntryPoint` 合约中实现的 DET 代币实例，且 CryptoVault 合约持有 100 单位的 DET 代币。
* 此外，CryptoVault 合约还持有 100 单位的 LegacyToken（LGT 代币）。
* 本关卡要求你找出 CryptoVault 合约中的漏洞，并保护其免受代币被盗取的攻击。
* 合约体系中包含一个 Forta 合约，任何用户均可注册自己的检测机器人（detection bot）合约。
* Forta 是一个去中心化的社区驱动型监控网络，旨在快速检测 DeFi、NFT、治理、跨链桥及其他 Web3 系统中的威胁与异常行为。
* 你的任务是实现一个检测机器人合约，并将其注册到 Forta 合约中。
* 该机器人需能触发正确的警报，以防范潜在的攻击或漏洞利用行为。

