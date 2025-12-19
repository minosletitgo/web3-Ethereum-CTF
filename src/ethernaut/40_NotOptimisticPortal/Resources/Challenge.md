<img src="./image.png" alt="" width="750">

### NotOptimisticPortal
* Difficulty：★★★★☆
* This portal relies on a complex chain of cryptographic proofs to verify cross-chain messages. 
* It claims to be secure against invalid state transitions, but the gap between verification and execution might be wider than it looks.
* Can you manage to mint some tokens for your wallet?
* Things that might help:
  - Understanding Function Selectors.
  - The Checks-Effects-Interactions (CEI) pattern.
  - Merkle Patricia Tries and RLP encoding.
* Tips:
  - Sometimes the data you verify isn't exactly the same data you execute.
  - If a hash cycle seems impossible to solve, look for a way to break the loop.

---------------------------------------------------------------------------------------------------------

# 非乐观式跨链门户
* 难度：★★★★☆
* 该门户依赖复杂的密码学证明链来验证跨链消息。
* 其宣称可防御非法状态转换，但验证与执行之间的间隙可能比表面看起来更宽。
* 你能否成功为自己的钱包铸造一些代币？
* 可能有帮助的知识点：
    - 理解函数选择器
    - 检查-效应-交互（CEI）设计模式
    - 默克尔帕特里夏树与递归长度前缀（RLP）编码
* 提示：
    - 有时你验证的数据与实际执行的数据并非完全一致。
    - 若某个哈希循环看似无法破解，尝试寻找打破循环的方法。
