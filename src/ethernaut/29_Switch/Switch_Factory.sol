// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../base/Level.sol";
import {Switch} from "./Switch.sol";

contract Switch_Factory is Level {
	function createInstance(address _player) public payable override returns (address) {
		_player; // 消除警告
		
		instance = address(new Switch());
		
		return instance;
	}
	
	function validateInstance(address _player) public view override returns (bool) {
		_player; // 消除警告
		Switch inst = Switch(payable(instance));
		return (inst.switchOn());
	}
}
