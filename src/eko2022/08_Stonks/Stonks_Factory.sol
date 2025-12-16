// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../base/Level.sol";
import "./Stonks.sol";

contract Stonks_Factory is Level {
	function createInstance(address _player) public payable override returns (address) {
		_player; // 消除警告
		instance = address(new Stonks(_player));
		return instance;
	}
	
	function validateInstance(address _player) public view override returns (bool) {
		_player; // 消除警告
		Stonks inst = Stonks(instance);
		return (inst.balanceOf(_player, inst.TSLA()) == 0 && inst.balanceOf(_player, inst.GME()) == 0);
	}
}
