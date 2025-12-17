// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../base/Level.sol";
import {BetHouse, Pool, PoolToken} from "./BetHouse.sol";

contract BetHouse_Factory is Level {
	function createInstance(address _player) public payable override returns (address) {
		_player; // 消除警告
		
		PoolToken _wrappedToken = new PoolToken("PoolWrappedToken", "PWT");
		PoolToken _depositToken = new PoolToken("PoolDepositToken", "PDT");
		
		Pool pool = new Pool(address(_wrappedToken), address(_depositToken));
		
		BetHouse betHouse = new BetHouse(address(pool));
		_depositToken.mint(_player, 5);
		
		_wrappedToken.transferOwnership(address(pool));
		_depositToken.transferOwnership(address(pool));
		
		instance = address(betHouse);
		
		return instance;
	}
	
	function validateInstance(address _player) public view override returns (bool) {
		_player; // 消除警告
		BetHouse inst = BetHouse(payable(instance));
		return (inst.isBettor(_player));
	}
}
