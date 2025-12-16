// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Recovery} from "../../src/ethernaut/17_Recovery/Recovery.sol";

contract Recovery_Attacker {
	address player;
	Recovery coreInst;
	
	constructor(Recovery coreInst_) payable {
		player = msg.sender;
		coreInst = coreInst_;
	}
	
	receive() external payable {}
	
	function doAttack() public {
		// Nothing
	}
}
