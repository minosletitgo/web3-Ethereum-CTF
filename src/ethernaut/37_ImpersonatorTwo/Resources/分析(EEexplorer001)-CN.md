# Ethernaut 第37关 冒充者二号

---

## 合约代码
```solidity
// 许可证标识符：MIT
pragma solidity 0.8.28;

import {Ownable} from "openzeppelin-contracts-08/access/Ownable.sol";
import {ECDSA} from "openzeppelin-contracts-08/utils/cryptography/ECDSA.sol";
import {Strings} from "openzeppelin-contracts-08/utils/Strings.sol";

contract ImpersonatorTwo is Ownable {
    using Strings for uint256;

    // 错误定义：非管理员
    error NotAdmin();
    // 错误定义：签名无效
    error InvalidSignature();
    // 错误定义：资金已锁定
    error FundsLocked();

    // 管理员地址
    address public admin;
    // 随机数/计数器
    uint256 public nonce;
    // 锁定状态
    bool locked;

    // 构造函数，支持接收以太币
    constructor() payable {}

    // 仅管理员可调用的修饰器
    modifier onlyAdmin() {
        require(msg.sender == admin, NotAdmin());
        _;
    }

    // 设置新管理员
    function setAdmin(bytes memory signature, address newAdmin) public {
        string memory message = string(abi.encodePacked("admin", nonce.toString(), newAdmin));
        require(_verify(hash_message(message), signature), InvalidSignature());
        nonce++;
        admin = newAdmin;
    }

    // 切换锁定状态
    function switchLock(bytes memory signature) public {
        string memory message = string(abi.encodePacked("lock", nonce.toString()));
        require(_verify(hash_message(message), signature), InvalidSignature());
        nonce++;
        locked = !locked;
    }

    // 提取资金（仅管理员）
    function withdraw() public onlyAdmin {
        require(!locked, FundsLocked());
        payable(admin).transfer(address(this).balance);
    }

    // 对消息进行哈希处理
    function hash_message(string memory message) public pure returns (bytes32) {
        return ECDSA.toEthSignedMessageHash(abi.encodePacked(message));
    }

    // 验证签名是否为合约所有者签署
    function _verify(bytes32 hash, bytes memory signature) internal view returns (bool) {
        return ECDSA.recover(hash, signature) == owner();
    }
}
```

## 攻击目标
我们的目标是提取合约中的所有余额并成为管理员。

要成为管理员并调用`withdraw()`函数，我们需要先调用`setAdmin(bytes memory signature, address newAdmin)`将自己设为管理员，再调用`switchLock(bytes memory signature)`解锁资金。这两个函数都需要由所有者链下签署的签名，这看起来几乎不可能实现。

但如果仔细分析合约，我们会发现这两个函数肯定至少被调用过一次。既然被调用过，就一定会留下交易记录。你可以在Etherscan上查看这两个函数的调用输入参数，也可以直接查看Ethernaut的源代码（地址：https://github.com/OpenZeppelin/ethernaut/blob/master/contracts/src/levels/ImpersonatorTwoFactory.sol ），从中找到这两个函数调用所使用的签名：

```solidity
// 切换锁定状态的签名
bytes constant SWITCH_LOCK_SIG = abi.encodePacked(
    hex"e5648161e95dbf2bfc687b72b745269fa906031e2108118050aba59524a23c40", // r值
    hex"70026fc30e4e02a15468de57155b080f405bd5b88af05412a9c3217e028537e3", // s值
    uint8(27) // v值
);
// 设置管理员的签名
bytes constant SET_ADMIN_SIG = abi.encodePacked(
    hex"e5648161e95dbf2bfc687b72b745269fa906031e2108118050aba59524a23c40", // r值
    hex"4c3ac03b268ae1d2aca1201e8a936adf578a8b95a49986d54de87cd0ccb68a79", // s值
    uint8(27) // v值
);
```

这里我们能发现一个**巨大的逻辑漏洞**：两个签名共享同一个r值，这意味着签名者使用了相同的随机数k来生成签名。我们可以通过这个漏洞直接计算出签名者的私钥。

回顾第32关“冒充者”和第35关“椭圆代币”中学习的椭圆曲线密码学知识：由于$R=kG$且$r=x(R) \mod n$，显然签名者为两个签名使用了相同的k值。由此我们得到两个方程：

$$
s_0 = k^{-1}(z_0 + re) \mod n \\
s_1 = k^{-1}(z_1 + re) \mod n
$$

首先计算k值：
$$
s_0 - s_1 = k^{-1}(z_0 - z_1) \mod n
$$

$$
k = Inv(s_0 - s_1) * (z_0 - z_1) \mod n
$$

再计算私钥e：
$$
e = Inv(r) * (ks_0 - z_0) \mod n
$$

这样我们就得到了签名者的**私钥**。

现在我们还知道nonce的当前值（现在从2开始），因此可以构造新的消息摘要，并用计算出的私钥进行链下签名。之后回到链上调用`setAdmin(bytes memory signature, address newAdmin)`和`switchLock(bytes memory signature)`来攻击合约。我们可以使用TypeScript脚本辅助完成这个过程。

### `recover_and_sign.ts`：
```typescript
// scripts/recover_and_sign.ts
// 恢复私钥并为新消息生成签名

import { ethers } from "ethers";

// 计算大数的模逆元（扩展欧几里得算法）
function modInverse(a: bigint, m: bigint): bigint {
  let [m0, x0, x1] = [m, 0n, 1n];
  let A = a % m;
  if (m === 1n) return 0n;
  while (A > 1n) {
    const q = A / m0;
    [A, m0] = [m0, A % m0];
    [x0, x1] = [x1 - q * x0, x0];
  }
  if (x1 < 0n) x1 += m;
  return x1;
}

async function main() {
  // 从命令行参数获取r、s0、z0、s1、z1、z2、z3的值
  const [rHex, s0Hex, z0Hex, s1Hex, z1Hex, z2Raw, z3Raw] = process.argv.slice(2);
  console.log("------------------检查输入参数------------------");
  console.log(rHex, s0Hex, z0Hex, s1Hex, z1Hex, z2Raw, z3Raw);
  console.log("-----------------------------------------------");

  // 检查参数是否完整
  if (!rHex || !s0Hex || !z0Hex || !s1Hex || !z1Hex || !z2Raw || !z3Raw) {
    console.error("使用方法: node recover_and_sign.ts <r> <s0> <z0> <s1> <z1> <z2> <z3>");
    process.exit(1);
  }

  // 将十六进制字符串转换为大整数
  const r = BigInt(rHex);
  const s0 = BigInt(s0Hex);
  const z0 = BigInt(z0Hex);
  const s1 = BigInt(s1Hex);
  const z1 = BigInt(z1Hex);

  // 椭圆曲线secp256k1的阶n
  const n = BigInt("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141");

  // 计算随机数k和私钥x
  const k = ((z0 - z1) * modInverse(s0 - s1, n)) % n;
  const x = ((s0 * k - z0) * modInverse(r, n)) % n;

  // 将私钥从大整数转换为32字节的十六进制字符串
  const xNorm = x < 0n ? x + n : x;
  const privKeyHex = ethers.toBeHex(xNorm, 32);

  // 用恢复的私钥创建钱包实例
  const wallet = new ethers.Wallet(privKeyHex);

  // 将输入的消息摘要规范化为32字节的十六进制格式
  const z2 = ethers.toBeHex(BigInt(z2Raw), 32);
  const z3 = ethers.toBeHex(BigInt(z3Raw), 32);

  // 获取签名密钥并为新消息生成签名
  const signingKey = wallet.signingKey;
  const sig2 = signingKey.sign(z2);
  const sig3 = signingKey.sign(z3);

  // 将签名序列化为r || s || v的十六进制格式
  const sig2Hex = ethers.concat([sig2.r, sig2.s, ethers.toBeHex(sig2.v, 1)]);
  const sig3Hex = ethers.concat([sig3.r, sig3.s, ethers.toBeHex(sig3.v, 1)]);

  // 输出生成的签名
  console.log(sig2Hex);
  console.log(sig3Hex);
}

// 执行主函数并捕获错误
main().catch((err) => {
  console.error("错误信息:", err);
  process.exit(1);
});
```

### `Impersonator.s.sol`：
```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {IImpersonatorTwo} from "../src/Interface.sol";

// 攻击脚本：通过FFI调用TypeScript脚本恢复私钥并生成签名
contract ImpersonatorTwoScript is Script {
    // 合约实例地址
    address constant instanceAddr = 0xea630140602d3551FBC00E4a6E67f8B95f9c213A;
    // 初始管理员地址
    address constant ADMIN = 0xADa4aFfe581d1A31d7F75E1c5a3A98b2D4C40f68;

    // 非ce为0的SWITCH_LOCK签名参数
    bytes32 r0 = hex"e5648161e95dbf2bfc687b72b745269fa906031e2108118050aba59524a23c40";
    bytes32 s0 = hex"70026fc30e4e02a15468de57155b080f405bd5b88af05412a9c3217e028537e3";
    uint8 v0 = 27;
    // 非ce为1的SET_ADMIN签名参数
    bytes32 r1 = hex"e5648161e95dbf2bfc687b72b745269fa906031e2108118050aba59524a23c40";
    bytes32 s1 = hex"4c3ac03b268ae1d2aca1201e8a936adf578a8b95a49986d54de87cd0ccb68a79";
    uint8 v1 = 27;
    
    // 合约实例接口
    IImpersonatorTwo instance = IImpersonatorTwo(instanceAddr);

    function run() external {
        vm.startBroadcast();
        // 获取调用者（攻击者）地址
        address player = msg.sender;

        // 计算非ce为0的lock消息哈希（z0）
        bytes32 z0 = IImpersonatorTwo(instanceAddr).hash_message(string(abi.encodePacked("lock", "0")));
        // 计算非ce为1的admin消息哈希（z1）
        bytes32 z1 = IImpersonatorTwo(instanceAddr).hash_message(string(abi.encodePacked("admin", "1", ADMIN)));

        // 计算非ce为2的lock消息哈希（z2）
        bytes32 z2 = IImpersonatorTwo(instanceAddr).hash_message(string(abi.encodePacked("lock", "2")));
        // 计算非ce为3的admin消息哈希（z3，设置攻击者为管理员）
        bytes32 z3 = IImpersonatorTwo(instanceAddr).hash_message(string(abi.encodePacked("admin", "3", player)));

        // 构建FFI命令，调用TypeScript脚本
        string[] memory cmd = new string[](10);
        cmd[0] = "yarn";
        cmd[1] = "ts-node";                              // 也可以使用其他TypeScript运行器（如node）
        cmd[2] = "./recover_and_sign.ts";
        cmd[3] = vm.toString(r0); // 传递r值
        cmd[4] = vm.toString(s0); // 传递s0值
        cmd[5] = vm.toString(z0); // 传递z0值
        cmd[6] = vm.toString(s1); // 传递s1值
        cmd[7] = vm.toString(z1); // 传递z1值
        cmd[8] = vm.toString(z2); // 传递z2值
        cmd[9] = vm.toString(z3); // 传递z3值

        // 执行FFI命令并获取输出（生成的签名）
        bytes memory out = vm.ffi(cmd);
        console.log("签名输出:\n", string(out));

        vm.stopBroadcast();
    }
}
```

**说明**：  
我已在`foundry.toml`中开启了`ffi=true`配置，因此可以在Solidity脚本中通过`yarn`调用TypeScript脚本。当我们恢复出私钥并生成新的签名后，就可以调用合约的`setAdmin`和`switchLock`函数来完成攻击。

`Solution.s.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {IImpersonatorTwo} from "../src/Interface.sol";

contract Solution is Script {
    address constant instanceAddr = 0xea630140602d3551FBC00E4a6E67f8B95f9c213A;
    IImpersonatorTwo instance = IImpersonatorTwo(instanceAddr);
    bytes sig2 = hex"84fe83b973cb36a59d8a0c7dde2d6a34e9e04a2c5b3d3a9470ea2ff338326f9a0fe56abd691abe411f69fbd82ca10fcdb13db04dc428b944f2de1bb8c801a6671b";
    bytes sig3 = hex"64ed58ff0fa4a85cbcf188cdaa13c05fb8f01a6e2ef9c278ca9025364a1d5e022f1b372cac547b6b64ddc03c0eeaf5bcecab249a129ef63a017eeac47e7b7c971b";

    function run() external {
        vm.startBroadcast();

        instance.switchLock(sig2);
        instance.setAdmin(sig3, msg.sender);
        instance.withdraw();

        console.log("New admin:", instance.admin());
        console.log("Contract balance:", address(instance).balance);

        vm.stopBroadcast();
    }
}
```
