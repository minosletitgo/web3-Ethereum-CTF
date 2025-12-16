// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Laboratory, Phoenixtto} from "../../src/eko2022/09_Phoenixtto/Phoenixtto.sol";

contract Phoenixtto_Attacker {
	address player;
	Laboratory laboratory;
	
	constructor(Laboratory laboratory_) {
		player = msg.sender;
		laboratory = laboratory_;
	}
	
	receive() external payable {}
	
	function doAttack() public {
		// Nothing
	}
}
