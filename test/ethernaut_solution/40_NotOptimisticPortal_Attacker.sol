// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {NotOptimisticPortal} from "../../src/ethernaut/40_NotOptimisticPortal/NotOptimisticPortal.sol";

contract NotOptimisticPortal_Attacker {
	address player;
	NotOptimisticPortal coreInst;
	
	constructor(NotOptimisticPortal coreInst_) payable {
		player = msg.sender;
		coreInst = coreInst_;
	}
	
	receive() external payable {}
	
	function doAttack() public {
		// Nothing
	}
}
