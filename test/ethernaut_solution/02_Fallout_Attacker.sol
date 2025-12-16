// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Fallout} from "../../src/ethernaut/02_Fallout/Fallout.sol";

contract Fallout_Attacker {
	address player;
	Fallout coreInst;
	
	constructor(Fallout coreInst_) payable {
		player = msg.sender;
		coreInst = coreInst_;
	}
	
	receive() external payable {}
	
	function doAttack() public {
		// Nothing
	}
}
