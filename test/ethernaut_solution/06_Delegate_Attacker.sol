// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Delegation, Delegate} from "../../src/ethernaut/06_Delegate/Delegate.sol";

contract Delegate_Attacker {
	address player;
	Delegation coreInst;
	
	constructor(Delegation coreInst_) payable {
		player = msg.sender;
		coreInst = coreInst_;
	}
	
	receive() external payable {}
	
	function doAttack() public {
		// Nothing
	}
}
