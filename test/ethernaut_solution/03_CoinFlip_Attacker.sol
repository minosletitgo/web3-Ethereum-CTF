// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {CoinFlip} from "../../src/ethernaut/03_CoinFlip/CoinFlip.sol";

contract CoinFlip_Attacker {
	address player;
	CoinFlip coreInst;
	
	constructor(CoinFlip coreInst_) payable {
		player = msg.sender;
		coreInst = coreInst_;
	}
	
	receive() external payable {}
	
	function doAttack() public {
		// Nothing
	}
}
