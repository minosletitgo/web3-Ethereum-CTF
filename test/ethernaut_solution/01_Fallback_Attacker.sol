// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Fallback} from "../../src/ethernaut/01_Fallback/Fallback.sol";

contract Fallback_Attacker {
	address player;
	Fallback fallbackInst;
	
	constructor(Fallback fallbackInst_) payable {
		player = msg.sender;
		fallbackInst = fallbackInst_;
	}
	
	receive() external payable {}
	
	function doAttack() public {
		// Nothing
	}
}
