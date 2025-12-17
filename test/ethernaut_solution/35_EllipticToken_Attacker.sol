// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {EllipticToken} from "../../src/ethernaut/35_EllipticToken/EllipticToken.sol";

contract EllipticToken_Attacker {
	address player;
	EllipticToken coreInst;
	
	constructor(EllipticToken coreInst_) payable {
		player = msg.sender;
		coreInst = coreInst_;
	}
	
	receive() external payable {}
	
	function doAttack() public {
		// Nothing
	}
}
