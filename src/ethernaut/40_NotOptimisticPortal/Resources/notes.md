### **1. 该 ERC20 合约在内部记录 L2 的一些状态数据，过程中使用了 MPT 与 RLP**
- 合约通过 `l2StateRoots` 数组缓存最近最多 1000 个 L2 区块的 **state root（状态根）**。
- 这些 state root 是从 L2 区块头中提取的，而区块头是以 **RLP 编码**传入的。
- 当用户要提现（`executeMessage`），合约会用 **MPT inclusion proof** 验证：
  > “你声称的这条消息，是否真的存在于某个已提交的 L2 状态中？”
- **RLP** 用于“读懂 L2 发来的原始数据”（区块头、账户状态）
- **MPT** 用于“验证某条数据是否真实存在于 L2 的全局状态中”
> 🔍 这不是以太坊底层自动做的，而是**合约主动实现的跨链验证逻辑**——这是高级应用（如桥、Rollup Portal）的典型模式。

### **2. Sequencer 调用 `submitNewBlock_____...` 表示 “L2 的状态更新”**
- `sequencer` 是 L2 的出块者（或代表），它负责将 L2 的新区块头（RLP 格式）提交到 L1。
- 合约通过 `_extractData` 解析出 `stateRoot`，并存入 `l2StateRoots[bufferCounter]`。
- 同时检查区块连续性（parent hash、block number +1、时间递增），防止乱序或伪造。
  > 注意：这里**没有欺诈证明窗口期**（不像 Optimism/Arbitrum 有 7 天挑战期），所以这是一个“非乐观”（NotOptimistic）Portal —— 一旦 sequencer 提交，就立刻信任！
- 这可能是 CTF 出题点：如果 sequencer 是恶意的，或验证逻辑有漏洞，就能伪造状态！

### **3. 在 L2 状态已更新的前提下，用户调用 `executeMessage`，触发 mint 等行为**
> **验证发生在执行之后？不！应该先验证，再执行。**
```solidity
function executeMessage(...) external nonReentrant {
    // ...计算 withdrawalHash
    // ...先执行消息（_executeOperation）
    for(...) { _executeOperation(...); }

    // ...此时，才验证???
    _verifyMessageInclusion(...);

    // ...最后 mint
}
```
- 正常流程应该是：
  1. 先验证消息在 L2 中确实存在（`_verifyMessageInclusion`）
  2. 再执行操作（mint、call 等）
- 不当的执行流程，意味着：
  - 攻击者可以传入任意 `_messageReceivers` 和 `_messageData`
  - 合约会**先尝试调用这些地址**（可能触发重入、消耗 gas、甚至改变状态）
  - **即使后续验证失败，前面的操作已经发生了！**
> 这可能是 CTF 的突破口之一：**在验证前执行恶意操作**（比如修改 storage、重入等）。



