# Ethernaut 第 19 关 MagicNumber 攻略：如何使用原始汇编操作码部署合约 | 作者：Nicole Zhu | Coinmonks | Medium

本关卡要求使用汇编编程向 EVM 部署一个极简合约。

![](https://miro.medium.com/v2/resize:fit:2000/format:webp/1*5Wrb7z3W6AMtjH6IKJYowg.jpeg)

让我们逐步拆解 :)

## 合约创建过程详解

回顾[合约初始化机制](https://medium.com/coinmonks/ethernaut-lvl-14-gatekeeper-2-walkthrough-how-contracts-initialize-and-how-to-do-bitwise-ddac8ad4f0fd)，合约创建会经历以下步骤：

1. **用户或合约向以太坊网络发送交易**：该交易包含数据，但未指定接收者地址。这种格式会告知 EVM 这是一笔「合约创建」交易，而非普通的转账/调用交易。
2. **EVM 将 Solidity 合约代码（高级人类可读语言）编译为字节码（低级机器可读语言）**：字节码直接对应操作码（opcode），这些操作码会在单一调用栈中执行。

> 重要提示：合约创建字节码包含两部分，按顺序拼接：
> 1) 初始化代码（initialization code）
> 2) 合约实际运行时代码（runtime code）

3. **合约创建期间，EVM 仅执行初始化代码**，直到遇到栈中的第一个 `STOP` 或 `RETURN` 指令。此阶段会执行合约的 `constructor()` 函数，同时合约地址会被生成。
4. **初始化代码执行完毕后，栈中仅保留运行时代码**：这些操作码会被复制到内存中，并返回给 EVM。
5. **最后，EVM 将返回的剩余代码存储到状态存储中**，与新合约地址关联。这部分运行时代码将在未来所有对该合约的调用中被栈执行。

### 简单总结

要解决本关卡，你需要两组操作码：

- **初始化操作码**：由 EVM 立即执行，用于创建合约并存储后续运行时操作码
- **运行时操作码**：包含合约实际执行逻辑，核心要求是**返回 0x42** 且操作码数量不超过 10 个

_如果你想独立解决本关卡，可深入阅读以下参考资料：_
_[操作码详解](https://medium.com/@blockchain101/solidity-bytecode-and-opcode-basics-672e9b1a88c2)_
_[智能合约解构](https://blog.zeppelin.solutions/deconstructing-a-solidity-contract-part-i-introduction-832efd2d7737)（本 Ethernaut 关卡作者撰写）_

_如需更多指导，继续阅读下文…_

## 详细攻略

![](https://miro.medium.com/v2/resize:fit:1100/format:webp/1*3oSxbDxt1O5IYzW1vX7MmQ.png)

0. 启动 [Ropsten 测试网的 Truffle 控制台](https://medium.com/coinmonks/5-minute-guide-to-deploying-smart-contracts-with-truffle-and-ropsten-b3e30d5ee1e)（或你偏好的开发环境），以便直接向 EVM 部署字节码。同时打开 [字节码与操作码转换表](https://github.com/ethereum/pyethereum/blob/develop/ethereum/opcodes.py) 备用。

## 运行时操作码 — 第一部分

首先设计运行时代码逻辑。关卡限制操作码数量不超过 10 个，而返回简单值 `0x42` 无需更多操作码。

**返回值**由 `RETURN` 操作码处理，该操作码接收两个参数：

- `p`：值在内存中的存储位置（例如 0x0、0x40、0x50，见图）。_我们任意选择 0x80 位置。_
- `s`：存储数据的长度。_注意：我们要返回的值是 32 字节（十六进制为 0x20）。_

_回顾以太坊内存结构，官方位置标识为 0x0、0x10、0x20… 如下所示：_

![](https://miro.medium.com/v2/resize:fit:640/format:webp/1*gkbvs_Csc4SusEMNegXcNQ.png)

每个以太坊交易拥有 2²⁵⁶ 字节的（临时）内存空间

但…这意味着在返回值之前，必须先将值存储到内存中。

1. 首先使用 `mstore(p, v)` 将 `0x42` 存储到内存（p 为位置，v 为十六进制值）：

```shell
6042    // v: push1 0x42（要存储的值）
6080    // p: push1 0x80（内存存储位置）
52      // mstore（执行存储操作）
```

2. 然后通过 `RETURN` 返回 `0x42`：

```shell
6020    // s: push1 0x20（数据长度 32 字节）
6080    // p: push1 0x80（数据存储在 0x80 位置）
f3      // return（执行返回操作）
```

最终运行时操作码序列为 `604260805260206080f3`，共 10 个操作码、10 字节。

## 初始化操作码 — 第二部分

接下来创建合约初始化操作码。这些操作码需要将运行时操作码复制到内存，然后返回给 EVM。_注意：EVM 会自动将返回的运行时序列 `604260805260206080f3` 存储到区块链，无需手动处理此步骤。_

**代码复制**由 `CODECOPY` 操作码处理，该操作码接收三个参数：

- `t`：代码在内存中的目标位置。_我们任意选择 0x00 位置。_
- `f`：运行时操作码在整个字节码中的起始位置。注意：`f` 的值是初始化代码结束后的索引。_这是一个先有鸡还是先有蛋的问题！目前该值未知。_
- `s`：代码长度（字节数）。_回顾：运行时操作码 `604260805260206080f3` 长 10 字节（十六进制为 0x0a）。_

3. 首先将运行时操作码复制到内存。`f` 的值暂时用占位符表示（目前未知）：

```shell
600a    // s: push1 0x0a（代码长度 10 字节）
60??    // f: push1 0x??（运行时操作码的起始位置，暂未知）
6000    // t: push1 0x00（内存目标位置 0x00）
39      // CODECOPY（执行复制操作）
```

4. 然后将内存中的运行时操作码返回给 EVM：

```shell
600a    // s: push1 0x0a（运行时操作码长度）
6000    // p: push1 0x00（读取内存 0x00 位置的数据）
f3      // return（返回给 EVM）
```

5. 注意：初始化操作码总长度为 12 字节（十六进制 0x0c）。因此运行时操作码的起始索引 `f` 为 `0x0c`（现在已知）：

```shell
600a    // s: push1 0x0a（代码长度 10 字节）
600c    // f: push1 0x0c（运行时操作码的起始位置）
6000    // t: push1 0x00（内存目标位置 0x00）
39      // CODECOPY（执行复制操作）
```

6. 最终初始化操作码序列如下：

```shell
0x600a600c600039600a6000f3604260805260206080f3
```

其中前 12 字节为初始化操作码，后 10 字节为运行时操作码。

7. 在 Truffle 控制台中，通过以下命令创建合约：

```shell
> var account = "你的钱包地址";
> var bytecode = "0x600a600c600039600a6000f3604260805260206080f3";
> web3.eth.sendTransaction({ from: account, data: bytecode }, function(err,res){console.log(res)});
```

8. 通过返回的交易哈希查询新创建的**合约地址**：可通过 Etherscan 或 `getTransactionReceipt(hash)` 方法查询。

9. 在 Ethernaut 网页控制台中，输入以下命令即可通关：

```javascript
await contract.setSolver("你的合约地址");
```
