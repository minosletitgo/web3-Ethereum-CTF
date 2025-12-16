// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {MagicNum} from "../../src/ethernaut/18_MagicNumber/MagicNumber.sol";

contract MagicNumber_Attacker {
	address player;
	MagicNum coreInst;
	
	constructor(MagicNum coreInst_) payable {
		player = msg.sender;
		coreInst = coreInst_;
	}
	
	receive() external payable {}
	
	function doAttack() public {
		// Nothing
	}
}
