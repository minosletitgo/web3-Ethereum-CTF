// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {ImpersonatorTwo} from "../../src/ethernaut/37_ImpersonatorTwo/ImpersonatorTwo.sol";

contract ImpersonatorTwo_Attacker {
	address player;
	ImpersonatorTwo coreInst;
	
	constructor(ImpersonatorTwo coreInst_) payable {
		player = msg.sender;
		coreInst = coreInst_;
	}
	
	receive() external payable {}
	
	function doAttack() public {
		// Nothing
	}
}
