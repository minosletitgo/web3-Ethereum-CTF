// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Privacy} from "../../src/ethernaut/12_Privacy/Privacy.sol";

contract Privacy_Attacker {
	address player;
	Privacy coreInst;
	
	constructor(Privacy coreInst_) payable {
		player = msg.sender;
		coreInst = coreInst_;
	}
	
	receive() external payable {}
	
	function doAttack() public {
		// Nothing
	}
}
