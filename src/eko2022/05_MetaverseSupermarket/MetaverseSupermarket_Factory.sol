// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../base/Level.sol";
import {InflaStore} from "./MetaverseSupermarket.sol";

contract MetaverseSupermarket_Factory is Level {
	function createInstance(address _player) public payable override returns (address) {
		_player; // 消除警告
		
		instance = address(new InflaStore(_player));
		
		return instance;
	}
	
	function validateInstance(address _player) public view override returns (bool) {
		_player; // 消除警告
		
		return (InflaStore(instance).meal().balanceOf(_player) > 0);
	}
}
