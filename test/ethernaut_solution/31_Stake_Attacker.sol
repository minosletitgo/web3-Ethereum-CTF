// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Stake} from "../../src/ethernaut/31_Stake/Stake.sol";

contract Stake_Attacker {
	address player;
	Stake coreInst;
	
	constructor(Stake coreInst_) payable {
		player = msg.sender;
		coreInst = coreInst_;
	}
	
	receive() external payable {}
	
	function doAttack() public {
		// Nothing
	}
}
