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

# 非乐观式跨链网关
* 难度：★★★★☆
* 该网关依托复杂的密码学证明链，完成跨链消息的有效性验证。。
* 尽管其宣称可抵御非法状态转换攻击，但验证环节与执行环节之间的安全间隙，可能远超表面所见。
* 你能否成功为自身钱包铸造代币？
* 可能有帮助的知识点：
    - 掌握函数选择器的原理与应用
    - 理解检查 - 效应 - 交互（CEI）设计模式
    - 熟悉默克尔帕特里夏树结构与 RLP 编码规则
* 提示：
    - 验证环节所使用的数据，未必与实际执行环节的数据完全一致。
    - 若遭遇看似无解的哈希循环困境，可尝试寻找打破循环的突破口。
