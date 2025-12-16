// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Stonks} from "../../src/eko2022/08_Stonks/Stonks.sol";

contract Stonks_Attacker {
	address player;
	Stonks stonks;
	
	constructor(Stonks stonks_) {
		player = msg.sender;
		stonks = stonks_;
	}
	
	receive() external payable {}
	
	function doAttack() public {
		//Nothing
	}
}
