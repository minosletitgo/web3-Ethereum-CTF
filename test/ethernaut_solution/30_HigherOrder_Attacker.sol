// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {HigherOrder} from "../../src/ethernaut/30_HigherOrder/HigherOrder.sol";

contract HigherOrder_Attacker {
	address player;
	HigherOrder coreInst;
	
	constructor(HigherOrder coreInst_) payable {
		player = msg.sender;
		coreInst = coreInst_;
	}
	
	receive() external payable {}
	
	function doAttack() public {
		// Nothing
	}
}
