# Ethernaut 第32关 仿冒者
我们的目标是让**任何**持有任意随机签名v、r和s的人都能打开`ECLocker`实例。

当我们调用`open(uint8 v, bytes32 r, bytes32 s)`函数时，内部函数`_isValidSignature(uint8 v, bytes32 r, bytes32 s)`会检查由(v, r, s)以及在构造函数中初始化的`msgHash`是否能通过`ecrecover`恢复出对该签名进行**签名**的地址。`msgHash`是签名对应的**消息**。该签名需要满足两个条件：

1. `_address == controller`：恢复出的地址必须是`controller`。
2. `!usedSignatures[signatureHash]`：该签名尚未被使用过。

要绕过第一个条件，我们需要调用`changeController(uint8 v, bytes32 r, bytes32 s, address newController)`函数，将`controller`地址**修改为零地址（address(0)）**。原因与`ecrecover`函数本身的特性有关：如果该函数无法恢复出地址（v、r、s错误或与`msgHash`不匹配），函数不会回滚（取消交易执行），而是从空内存中读取返回数据，因此会返回零地址。

然而，我们不能使用构造函数中使用的完全相同的签名来**修改控制器**，因为该签名已经被使用过（第二个条件）。那我们该如何操作呢？

我们可以先把这个问题放在一边，深入分析一下构造函数——这是代码中最复杂的部分。虽然这部分本身与解决方案没有直接关联，但理解`ecrecover`的底层工作原理至关重要。这部分内容参考自[这里](https://medium.com/@ynyesto/ethernaut-32-impersonator-825c0ea9d76d)。

### 构造函数
```solidity
bytes32 _msgHash;
assembly {
    mstore(0x00, "\x19Ethereum Signed Message:\n32") // 28字节
    mstore(0x1C, _lockId) // 32字节
    _msgHash := keccak256(0x00, 0x3c) //28 + 32 = 60字节
}
msgHash = _msgHash;
```

在这部分代码中，我们需要利用唯一的`_lockId`构造`msgHash`。内存中前28字节是字符串头部，紧接着是32字节的`_lockId`。然后我们对这60字节的数据进行哈希运算，并将结果存储在`msgHash`中。

```solidity
assembly {
            let ptr := mload(0x40)
            mstore(ptr, _msgHash) // 32字节
            mstore(add(ptr, 32), mload(add(_signature, 0x60))) // 32字节的v
            mstore(add(ptr, 64), mload(add(_signature, 0x20))) // 32字节的r
            mstore(add(ptr, 96), mload(add(_signature, 0x40))) // 32字节的s
            pop(
                staticcall(
                    gas(), // 交易剩余的燃气量
                    initialController, // ecrecover预编译合约的地址
                    ptr, // 输入数据的起始位置
                    0x80, // 输入数据的大小
                    0x00, // 输出数据的起始位置
                    0x20 // 输出数据的大小
                )
            )
            if iszero(returndatasize()) {
                mstore(0x00, 0x8baa579f) // 自定义错误InvalidSignature()的选择器
                revert(0x1c, 0x04)
            }
            initialController := mload(0x00)
            mstore(0x40, add(ptr, 128))
        }
```

首先声明一个指针`ptr`，并将其初始化为内存位置`0x40`存储的内容，然后将上面计算出的消息哈希存储在`ptr`指向的内存槽中。需要注意的是，在Solidity中有一个约定：自由内存指针（指向合约内存中第一个空闲槽的指针）存储在内存位置`0x40`，其值初始为`0x80`（128），并随内存分配而增加。

接下来，从`_signature`参数中提取ECDSA的v、r、s值——每次从内存中加载32字节的数据，然后将这三个值分别存储在消息哈希相邻的空闲内存槽中（`_msgHash`存储在`ptr`指向的槽，v、r、s分别存储在偏移32、64、96字节的槽中）。

然后执行一次外部调用，并用`pop()`语句丢弃其返回值（详见Solidity汇编文档），避免其留在栈中。这次`staticcall`调用的地址是`ecrecover`预编译合约，输入数据从`ptr`开始，大小为128（十六进制0x80）字节。因此，发送的数据包括`_msgHash`和刚刚存储的三个ECDSA参数。调用的输出数据存储在内存位置`0x00`，覆盖了之前存储在该位置的消息前缀和`0x1c`位置的`_lockId`起始部分（这些数据已不再需要）。

随后检查返回数据的大小，如果返回数据大小为零，则合约部署应回滚并抛出`InvalidSignature()`自定义错误——因为这意味着返回的地址是零地址，即签名无效。如果未触发回滚，则将返回的地址存储在`initialController`中（覆盖之前的0x01地址），并更新自由内存指针，使其继续指向合约内存中第一个空闲的槽（现在比原来大128字节，因为消息哈希和ECDSA参数存储在从`ptr`开始的槽中）。

### ECDSA签名的可延展性
我们还需要了解ECDSA的基础知识以及基于其特性的签名可延展性。

![椭圆曲线](https://upload.wikimedia.org/wikipedia/commons/d/da/Elliptic_curve_simple.svg)

上图是我们用于生成(v, r, s)的椭圆曲线。我们无需深入研究ECDSA密码学的数学原理，只需知道在比特币和以太坊使用的**Secp256k1**曲线中，曲线关于**x轴对称**——这导致了一个事实：对于同一个私钥签名的消息，存在两个有效的签名，一个对应曲线的正y半轴，另一个对应负y半轴（此处不深入ECDSA的数学细节）。

v的实际值为27或28，用于表示签名位于曲线的哪一侧。由于对称性，我们可以计算出一个新的s' = n - s，其中n是由生成点G生成的椭圆曲线点子群的阶。在**Secp256k1**中，n的固定值为`0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141`。

因此，对于每个签名(v, r, s)，都有一个对应的“仿冒者”签名(v', r, s')，位于曲线的另一侧。这被称为**签名可延展性**。

### 攻击思路
我们可以利用这一特性来回答之前提出的问题：如何修改控制器？答案是使用**仿冒者**签名(v', r, s')来调用`changeController`——因为(v, r, s)和(v', r, s')都能恢复出原始签名者的同一个公钥，因此我们可以轻松满足前面提到的两个条件。

为了计算(v', r, s')，我们首先需要获取(v, r, s)。由于`Impersonator`是一个`Ownable`合约且有存储保护，我们无法使用`await web3.eth.getStorageAt()`这样的技巧。一个简单的方法是在**Etherscan**上查看合约的事件日志：搜索实例地址并进入事件日志页面，你会看到类似以下的内容：

```
NewLock (index_topic_1 address lockAddress, uint256 lockId, uint256 timestamp, bytes signature)

[topic0] 0xac736e29adaa5052dee435c56ab8fe44ca41d6e5337e6b528e771ac85e97b7c3  
[topic1] 0x00000000000000000000000003fe6ac034d9b19c2286dc4717462e679d69f7062  

十六进制转储 →  
0000000000000000000000000000000000000000000000000000000000000539  
0000000000000000000000000000000000000000000000000000000068ff0ac  
0000000000000000000000000000000000000000000000000000000000000060  
1932cb842d3e27f54f79f7be0289437381ba2410fdefbae36850bee9c41e3b91  
78489c64a0db16c40ef986beccc8f069ad5041e5b992d76fe76bba057d9abff2  
000000000000000000000000000000000000000000000000000000000000001b
```

这是触发的`NewLock`事件：
- [topic0]是事件本身的选择器
- [topic1]存储了索引化的`lockAddress`
- 接下来的两个bytes32分别是`uint256 lockId`和`uint256 timestamp`
- 再往后的五个槽用于存储`bytes signature`：
    - 第一个0x60是偏移量，表示实际数据从第四个32字节槽开始
    - 第二个0x60是数据长度，表示占用3个完整的32字节槽
    - 最后三个槽分别对应r、s和v

所需的所有数据都在这里了，现在我们可以编写攻击逻辑：

`Impersonator.s.sol`:
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {Impersonator, ECLocker} from "../src/Impersonator.sol";

contract ImpersonatorScript is Script {
    Impersonator impersonator = Impersonator(0xXXXXXXXXX); // 替换为实际的Impersonator合约地址
    ECLocker locker = impersonator.lockers(0);
    // Secp256k1曲线的n值
    bytes32 constant N = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

    function run() external {
        vm.startBroadcast();
        // 从Etherscan事件日志中提取的原始签名值
        uint8 v = 0x1b;
        bytes32 r = 0x1932cb842d3e27f54f79f7be0289437381ba2410fdefbae36850bee9c41e3b91;
        bytes32 s = 0x78489c64a0db16c40ef986beccc8f069ad5041e5b992d76fe76bba057d9abff2;

        // 计算仿冒签名的v和s
        uint8 new_v = (v == 27 ? 28 : 27);
        bytes32 new_s = bytes32(uint256(N) - uint256(s));

        // 调用changeController将控制器修改为零地址
        locker.changeController(new_v, r, new_s, address(0));

        vm.stopBroadcast();
    }
}
```

注意，v的类型是`uint8`。
