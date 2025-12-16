# Solidity 游戏 - PuzzleWallet 攻击

_灵感来自 OpenZeppelin 的 [Ethernaut](https://ethernaut.openzeppelin.com)，PuzzleWallet 关卡_

⚠️切勿在主网尝试！

## 任务

如今，为去中心化金融（DeFi）操作支付手续费几乎是难以承受的事实。

一群开发者发现了一种能略微降低多笔交易成本的方法——将这些交易批量处理在一笔交易中，于是他们开发了一个智能合约来实现这个功能。

他们需要这个合约具备可升级性，以防代码中存在漏洞；同时还希望阻止外部人员使用该合约。为此，他们投票选出了两位拥有特殊权限的角色：
- 管理员（admin）：拥有更新智能合约逻辑的权限
- 所有者（owner）：掌控允许使用合约的地址白名单

合约部署完成后，团队成员的地址被加入白名单，所有人都为他们攻克矿工高额手续费的成果欢呼雀跃。

但他们万万没想到，自己的“午餐钱”正面临风险……

你的任务是劫持这个钱包，成为代理合约（proxy）的管理员。

_提示：_
1. 理解 `delegatecall` 的工作原理，以及执行 `delegatecall` 时 `msg.sender` 和 `msg.value` 的行为特性
2. 了解代理模式（Proxy Pattern）及其处理存储变量的方式

## 你将学到什么

1. `delegatecall` 漏洞的核心原理
2. 代理合约与实现合约之间的存储槽位（storage slot）顺序问题

## 目标合约

⚠️本合约存在漏洞和风险，请勿在主网使用！

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/proxy/UpgradeableProxy.sol";

contract PuzzleProxy is UpgradeableProxy {
    address public pendingAdmin; // 待确认的管理员
    address public admin; // 当前管理员

    constructor(address _admin, address _implementation, bytes memory _initData) UpgradeableProxy(_implementation, _initData) public {
        admin = _admin;
    }

    modifier onlyAdmin {
      require(msg.sender == admin, "Caller is not the admin"); // 仅管理员可调用
      _;
    }

    // 提议新管理员
    function proposeNewAdmin(address _newAdmin) external {
        pendingAdmin = _newAdmin;
    }

    // 批准新管理员（仅当前管理员可操作）
    function approveNewAdmin(address _expectedAdmin) external onlyAdmin {
        require(pendingAdmin == _expectedAdmin, "Expected new admin by the current admin is not the pending admin");
        admin = pendingAdmin;
    }

    // 升级实现合约（仅管理员可操作）
    function upgradeTo(address _newImplementation) external onlyAdmin {
        _upgradeTo(_newImplementation);
    }
}

contract PuzzleWallet {
    using SafeMath for uint256;
    address public owner; // 合约所有者
    uint256 public maxBalance; // 钱包最大余额限制
    mapping(address => bool) public whitelisted; // 白名单地址映射
    mapping(address => uint256) public balances; // 地址余额映射

    // 初始化函数
    function init(uint256 _maxBalance) public {
        require(maxBalance == 0, "Already initialized"); // 防止重复初始化
        maxBalance = _maxBalance;
        owner = msg.sender;
    }

    modifier onlyWhitelisted {
        require(whitelisted[msg.sender], "Not whitelisted"); // 仅白名单地址可调用
        _;
    }

    // 设置最大余额（仅白名单地址可操作）
    function setMaxBalance(uint256 _maxBalance) external onlyWhitelisted {
      require(address(this).balance == 0, "Contract balance is not 0"); // 合约余额必须为0
      maxBalance = _maxBalance;
    }

    // 添加地址到白名单（仅所有者可操作）
    function addToWhitelist(address addr) external {
        require(msg.sender == owner, "Not the owner");
        whitelisted[addr] = true;
    }

    // 存款（仅白名单地址可操作）
    function deposit() external payable onlyWhitelisted {
      require(address(this).balance <= maxBalance, "Max balance reached"); // 不超过最大余额限制
      balances[msg.sender] = balances[msg.sender].add(msg.value);
    }

    // 执行交易（仅白名单地址可操作）
    function execute(address to, uint256 value, bytes calldata data) external payable onlyWhitelisted {
        require(balances[msg.sender] >= value, "Insufficient balance"); // 余额充足
        balances[msg.sender] = balances[msg.sender].sub(value);
        (bool success, ) = to.call{ value: value }(data);
        require(success, "Execution failed"); // 执行成功
    }

    // 批量调用（仅白名单地址可操作）
    function multicall(bytes[] calldata data) external payable onlyWhitelisted {
        bool depositCalled = false; // 标记deposit是否已调用
        for (uint256 i = 0; i < data.length; i++) {
            bytes memory _data = data[i];
            bytes4 selector;
            assembly {
                selector := mload(add(_data, 32)) // 获取函数选择器
            }
            if (selector == this.deposit.selector) {
                require(!depositCalled, "Deposit can only be called once"); // deposit只能调用一次
                // 防止重复使用msg.value
                depositCalled = true;
            }
            (bool success, ) = address(this).delegatecall(data[i]);
            require(success, "Error while delegating call"); // 代理调用成功
        }
    }
}
```

## 剧透：解决方案 🤐

### 核心知识点

**`delegatecall`**

`delegatecall` 本质上意味着：我（当前合约）允许你（目标合约）对我的存储进行任意操作。对于发起 `delegatecall` 的合约来说，这是一种安全风险——它需要信任被调用合约会妥善处理其存储。
举个例子：如果 Alice 调用 Bob，而 Bob 通过 `delegatecall` 调用 Charlie，那么 `delegatecall` 中的 `msg.sender` 仍然是 Alice。也就是说，`delegatecall` 会使用目标合约的代码，但操作的是当前合约的存储。

**代理模式（Proxy Pattern）**

以太坊最大的优势之一是：所有资金转移、合约部署和合约交易都永久记录在我们称之为区块链的公共账本上，无法隐藏或修改。这使得以太坊成为一个极其稳健的去中心化系统——网络中的任何节点都能验证每笔交易的有效性和状态。
但最大的缺点是：智能合约部署后，其源代码无法修改。而中心化应用（如 Facebook、Airbnb）的开发者习惯通过频繁更新来修复漏洞或引入新功能，这在传统以太坊合约模式下无法实现。

因此，为了构建可升级合约，我们可以设计一个代理合约作为用户交互入口，将请求转发到逻辑合约（实现合约）。所有代理合约都通过 `delegatecall` 来执行逻辑合约中的代码。

### 漏洞分析

简单来说，代理合约（Proxy）和逻辑合约（Logic）通过 `delegatecall` 共享存储，这意味着：
- `pendingAdmin`（代理合约）对应 `owner`（逻辑合约）
- `admin`（代理合约）对应 `maxBalance`（逻辑合约）

| 存储槽位 | 代理合约变量       | 逻辑合约变量   |
|----------|--------------------|----------------|
| 0        | pendingAdmin       | owner          |
| 1        | admin              | maxBalance     |
| 2        | -                  | whitelisted    |
| 3        | -                  | balances       |

由此可以推断，我们可以通过修改 `maxBalance` 来设置 `admin` 的值。
要修改 `maxBalance`，需要满足两个条件：
1. 调用者必须在白名单中
2. 钱包合约的以太币余额必须为 0

要将地址加入白名单，需要成为 `owner`；
要成为 `owner`，可以通过调用 `PuzzleProxy` 中的 `proposeNewAdmin` 将 `pendingAdmin` 设置为自己（因为 `pendingAdmin` 对应 `owner`）。

一旦进入白名单，就可以通过巧妙调用 `execute` 和 `multicall` 来窃取合约中的以太币。

### 攻击步骤

1. 将自己提议为新管理员（修改 `pendingAdmin`，即 `owner`）
2. 将自己加入白名单
3. 操纵自己的余额
4. 提取合约中所有 ETH：
   - 调用 `multicall([deposit, multicall([deposit])])` 实现余额翻倍
   - 调用 `execute` 将 ETH 提取到自己地址
5. 设置 `maxBalance`（即修改 `admin`），成为代理合约的管理员

## 配置说明

### 安装依赖

```
yarn install
```

## 测试与攻击！💥

### 运行测试

```
yarn test
```

你应该会看到如下结果：

```
  Hacker
    √ initialize a PuzzleWallet and setup the game (186ms)
    Attack
      √ propose new admin for proxy, it should update owner for wallet (44ms)
      √ add hacker in whitelist
      √ manipulate hacker balance to be double (58ms)
      √ drain all ether out from the wallet
      √ set maxBalance again, it should finally change the admin of the proxy


  6 passing (641ms)
```

### 测试结果中文翻译：
```
  黑客
    √ 初始化PuzzleWallet并设置游戏环境 (186ms)
    攻击流程
      √ 提议新的代理管理员，应更新钱包的所有者 (44ms)
      √ 将黑客地址加入白名单
      √ 操纵黑客余额使其翻倍 (58ms)
      √ 提取钱包中所有以太币
      √ 重新设置maxBalance，最终应修改代理合约的管理员


  6个测试用例通过 (641ms)
```
