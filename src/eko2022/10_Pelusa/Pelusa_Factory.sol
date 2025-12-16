// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../base/Level.sol";
import "./Pelusa.sol";

contract Pelusa_Factory is Level {
	function createInstance(address _player) public payable override returns (address) {
		_player; // 消除警告
		instance = address(new Pelusa());
		return instance;
	}
	
	function validateInstance(address _player) public view override returns (bool) {
		_player; // 消除警告
		Pelusa inst = Pelusa(instance);
		return inst.goals() == 2;
	}
}
