// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Stake} from "../../src/ethernaut/31_Stake/Stake.sol";
import {WETH9} from "../../src/ethernaut/helpers/WETH9.sol";
import {Stake_Factory} from "../../src/ethernaut/31_Stake/Stake_Factory.sol";
import {Stake_Attacker} from "./31_Stake_Attacker.sol";

contract Stake_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");

	Stake_Factory factory;
	Stake instContract;
	
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
		
		factory = new Stake_Factory();
		instContract = Stake(payable(factory.createInstance{value: 100 ether}(player)));
		
		vm.stopPrank();
		
		vm.deal(address(player), 101 ether);
	}
	
	function test__Solution_Stake() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_Stake -vv
		
		// 核心问题：
		// (bool transfered, ) = WETH.call(abi.encodeWithSelector(0x23b872dd, msg.sender,address(this),amount));
		// 不知所云
		
		WETH9 wethContract = WETH9(payable(instContract.WETH()));
		
		wethContract.deposit{value: 0.1 ether}();
		wethContract.approve(address(instContract), 0.1 ether);
		instContract.StakeWETH(0.1 ether);
		instContract.Unstake(0.1 ether);
	}
}
