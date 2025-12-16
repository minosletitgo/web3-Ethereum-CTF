// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {console} from "forge-std/console.sol";

contract Denial {
	address public partner; // 提款合伙人 - 支付燃气费，分享提款收益
	address public constant owner = address(0xA9E); // 合约所有者地址
	uint256 timeLastWithdrawn; // 上次提款时间
	mapping(address => uint256) withdrawPartnerBalances; // 记录合伙人的余额
	
	function setWithdrawPartner(address _partner) public {
		partner = _partner; // 设置提款合伙人
	}
	
	// 向接收方和所有者各提款1%
	function withdraw() public {
		uint256 amountToSend = address(this).balance / 100; // 计算提款金额（合约余额的1%）
		// 执行调用但不检查返回值
		// 接收方可能会回滚，但所有者仍将获得其份额
		partner.call{value: amountToSend}(""); // 向合伙人发送提款金额
		// console.log("withdraw:11111111111");
		payable(owner).transfer(amountToSend); // 向所有者发送提款金额
		// console.log("withdraw:222222222222");
		// 记录上次提款时间
		timeLastWithdrawn = block.timestamp;
		withdrawPartnerBalances[partner] += amountToSend; // 更新合伙人的余额
		// console.log("withdraw:33333333333");
	}
	
	// 允许存入资金
	receive() external payable {}
	
	// 便捷函数：获取合约余额
	function contractBalance() public view returns (uint256) {
		return address(this).balance;
	}
}
