// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Vault} from "../../src/ethernaut/08_Vault/Vault.sol";
import {Vault_Factory} from "../../src/ethernaut/08_Vault/Vault_Factory.sol";
import {Vault_Attacker} from "./08_Vault_Attacker.sol";

contract Vault_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");
	
	Vault_Factory factory;
	Vault instContract;
	
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
		
		factory = new Vault_Factory();
		instContract = Vault(payable(factory.createInstance(player)));
		
		vm.stopPrank();
		
		vm.deal(address(player), 101 ether);
	}
	
	function test__Solution_Vault() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_Vault -vv
		
		bytes32 password = vm.load(address(instContract), bytes32(uint256(1)));
		instContract.unlock(password);
	}
}
