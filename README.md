### EKO 区块链夺旗赛
- 原址：https://www.ctfprotocol.com/tracks/eko2022
- 本系列挑战由一众顶尖黑客为 [EKOparty 2022](https://www.ekoparty.org/) 赛事打造，出题者包括：[@Br0niclΞ](https://twitter.com/Cryptonicle1)、[@nicobevi.eth](https://twitter.com/nicobevi_eth)、[@matta](https://twitter.com/mattaereal)、[@tinchoabbate](https://twitter.com/tinchoabbate)、[@adriro](https://twitter.com/adrianromero)、[@bengalaQ](https://twitter.com/AugustitoQ)、[@chiin](https://linktr.ee/chiin.eth)、[@Rotciv](https://twitter.com/victor93389091)、[@Bahurum](https://twitter.com/bahurum) 及 [@0x4non](https://twitter.com/eugenioclrc)……
- 特别感谢 [@patrickd](https://twitter.com/patrickd_de) 对合约提供的快速审核与反馈：D

| 序号 | 挑战名称 (中文)        | 挑战名称 (英文)                          | 跳转到`题目说明`                                                        | 跳转到`源码`                                                            | 跳转到`解决方案测试单元`                                               
|:--:|:---------------------|:-----------------------------------|:-----------------------------------------------------------------|:-------------------------------------------------------------------|:------------------------------------------------------------
| 1  | 迷失的小猫             | TheLostKitty                       | [点击](src/eko2022/01_TheLostKitty/Resources/Challenge.md)         | [点击](src/eko2022/01_TheLostKitty/TheLostKitty.sol)                 | [点击](./test/eko2022_solution/01_TheLostKitty.t.sol)         |
| 2  | 入侵母舰             | HackTheMotherShip                  | [点击](src/eko2022/02_HackTheMotherShip/Resources/Challenge.md)    | [点击](src/eko2022/02_HackTheMotherShip/HackTheMotherShip.sol)       | [点击](./test/eko2022_solution/02_HackTheMotherShip.t.sol)    |
| 3  | 欺诈者             | Trickster                          | [点击](src/eko2022/03_Trickster/Resources/Challenge.md)            | [点击](src/eko2022/03_Trickster/Trickster.sol)                       | [点击](./test/eko2022_solution/03_Trickster.t.sol)            |
| 4  | 提权破解             | RootMe                             | [点击](src/eko2022/04_RootMe/Resources/Challenge.md)               | [点击](src/eko2022/04_RootMe/RootMe.sol)                             | [点击](./test/eko2022_solution/04_RootMe.t.sol)               |
| 5  | 元宇宙超市             | MetaverseSupermarket              | [点击](src/eko2022/05_MetaverseSupermarket/Resources/Challenge.md) | [点击](src/eko2022/05_MetaverseSupermarket/MetaverseSupermarket.sol) | [点击](./test/eko2022_solution/05_MetaverseSupermarket.t.sol) |
| 6  | 智能魂器             | SmartHorrocrux              | [点击](src/eko2022/06_SmartHorrocrux/Resources/Challenge.md)       | [点击](src/eko2022/06_SmartHorrocrux/SmartHorrocrux.sol)             | [点击](./test/eko2022_solution/06_SmartHorrocrux.t.sol)       |
| 7  | 黄金门票             | TheGoldenTicket              | [点击](src/eko2022/07_TheGoldenTicket/Resources/Challenge.md)      | [点击](src/eko2022/07_TheGoldenTicket/TheGoldenTicket.sol)           | [点击](./test/eko2022_solution/07_TheGoldenTicket.t.sol)      |
| 8  | 股票操盘             | Stonks              | [点击](src/eko2022/08_Stonks/Resources/Challenge.md)               | [点击](src/eko2022/08_Stonks/Stonks.sol)                             | [点击](./test/eko2022_solution/08_Stonks.t.sol)               |
| 9  | 凤凰重生             | Phoenixtto              | [点击](src/eko2022/09_Phoenixtto/Resources/Challenge.md)           | [点击](src/eko2022/09_Phoenixtto/Phoenixtto.sol)                     | ❌[点击](./test/eko2022_solution/09_Phoenixtto.t.sol)           |
| 10 | 球王绝技             | Pelusa              | [点击](src/eko2022/10_Pelusa/Resources/Challenge.md)               | [点击](src/eko2022/10_Pelusa/Pelusa.sol)                             | [点击](./test/eko2022_solution/10_Pelusa.t.sol)               |
| 11 | 燃气阀门             | GasValve              | [点击](src/eko2022/11_GasValve/Resources/Challenge.md)               | [点击](src/eko2022/11_GasValve/GasValve.sol)                                   | [点击](./test/eko2022_solution/11_GasValve.t.sol)               |

-------------------------------------------------------

### 以太坊夺旗赛
- 原址：https://ethernaut.openzeppelin.com
- 一款基于 Web3 的夺旗游戏，灵感源自 OverTheWire，需在以太坊虚拟机（EVM）中进行。每个关卡对应一个需被「破解」的智能合约。
- 该游戏既是以太坊爱好者的学习工具，也是历史黑客事件的关卡化收录平台。游戏关卡数量不限，且无需按特定顺序游玩。

| 序号 | 难度指数  | 挑战名称 (中文) | 挑战名称 (英文)     | 跳转到`题目描述`                                                     | 跳转到`源码`                                                  | 跳转到`解决方案测试单元`                                          |
|:--:|:-----:|:----------|:--------------|:--------------------------------------------------------------|:---------------------------------------------------------|:-------------------------------------------------------|
| 1  | ★☆☆☆☆ | 回退函数      | Fallback      | [点击](./src/ethernaut/01_Fallback/Resources/Challenge.md)      | [点击](./src/ethernaut/01_Fallback/Fallback.sol)           | [点击](./test/ethernaut_solution/01_Fallback.t.sol)      |
| 2  | ★☆☆☆☆ | 尘埃无形      | Fallout       | [点击](./src/ethernaut/02_Fallout/Resources/Challenge.md)       | [点击](./src/ethernaut/02_Fallout/Fallout.sol)             | [点击](./test/ethernaut_solution/02_Fallout.t.sol)       |
| 3  | ★★☆☆☆ | 猜硬币	      | CoinFlip      | [点击](./src/ethernaut/03_CoinFlip/Resources/Challenge.md)      | [点击](./src/ethernaut/03_CoinFlip/CoinFlip.sol)           | [点击](./test/ethernaut_solution/03_CoinFlip.t.sol)      |
| 4  | ★☆☆☆☆ | 电话	       | Telephone     | [点击](./src/ethernaut/04_Telephone/Resources/Challenge.md)     | [点击](./src/ethernaut/04_Telephone/Telephone.sol)         | [点击](./test/ethernaut_solution/04_Telephone.t.sol)     |
| 5  | ★★☆☆☆ | 代币	       | Token         | [点击](./src/ethernaut/05_Token/Resources/Challenge.md)         | [点击](./src/ethernaut/05_Token/Token.sol)                 | [点击](./test/ethernaut_solution/05_Token.t.sol)         |
| 6  | ★★☆☆☆ | 委托	       | Delegate      | [点击](./src/ethernaut/06_Delegate/Resources/Challenge.md)      | [点击](./src/ethernaut/06_Delegate/Delegate.sol)           | [点击](./test/ethernaut_solution/06_Delegate.t.sol)      |
| 7  | ★★★☆☆ | 强制转账	     | Force         | [点击](./src/ethernaut/07_Force/Resources/Challenge.md)         | [点击](./src/ethernaut/07_Force/Force.sol)                 | [点击](./test/ethernaut_solution/07_Force.t.sol)         |
| 8  | ★★☆☆☆ | 金库	       | Vault         | [点击](./src/ethernaut/08_Vault/Resources/Challenge.md)         | [点击](./src/ethernaut/08_Vault/Vault.sol)                 | [点击](./test/ethernaut_solution/08_Vault.t.sol)         |
| 9  | ★★★☆☆ | 国王	       | King          | [点击](./src/ethernaut/09_King/Resources/Challenge.md)          | [点击](./src/ethernaut/09_King/King.sol)                   | [点击](./test/ethernaut_solution/09_King.t.sol)          |
| 10 | ★★★☆☆ | 重入攻击	     | Reentrance    | [点击](./src/ethernaut/10_Reentrance/Resources/Challenge.md)    | [点击](./src/ethernaut/10_Reentrance/Reentrance.sol)       | [点击](./test/ethernaut_solution/10_Reentrance.t.sol)    |
| 11 | ★★☆☆☆ | 电梯	       | Elevator      | [点击](./src/ethernaut/11_Elevator/Resources/Challenge.md)      | [点击](./src/ethernaut/11_Elevator/Elevator.sol)           | [点击](./test/ethernaut_solution/11_Elevator.t.sol)      |
| 12 | ★★★☆☆ | 隐私保护	     | Privacy       | [点击](./src/ethernaut/12_Privacy/Resources/Challenge.md)       | [点击](./src/ethernaut/12_Privacy/Privacy.sol)             | [点击](./test/ethernaut_solution/12_Privacy.t.sol)       |
| 13 | ★★★★☆ | 守门人一号	    | GatekeeperOne | [点击](./src/ethernaut/13_GatekeeperOne/Resources/Challenge.md) | [点击](./src/ethernaut/13_GatekeeperOne/GatekeeperOne.sol) | [点击](./test/ethernaut_solution/13_GatekeeperOne.t.sol) |
| 14 | ★★★☆☆  | 守门人二号	    | GatekeeperTwo | [点击](./src/ethernaut/14_GatekeeperTwo/Resources/Challenge.md) | [点击](./src/ethernaut/14_GatekeeperTwo/GatekeeperTwo.sol) | [点击](./test/ethernaut_solution/14_GatekeeperTwo.t.sol) |
| 15 | ★★★☆☆  | 零币合约	    | NaughtCoin | [点击](./src/ethernaut/15_NaughtCoin/Resources/Challenge.md)    | [点击](./src/ethernaut/15_NaughtCoin/NaughtCoin.sol)       | [点击](./test/ethernaut_solution/15_NaughtCoin.t.sol)    |
| 16 | ★★★★☆  | 时间存储	    | Preservation | [点击](./src/ethernaut/16_Preservation/Resources/Challenge.md)  | [点击](./src/ethernaut/16_Preservation/Preservation.sol)   | [点击](./test/ethernaut_solution/16_Preservation.t.sol)  |
