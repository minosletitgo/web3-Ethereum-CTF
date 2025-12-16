// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../base/Level.sol";
import "./TheLostKitty.sol";

contract TheLostKitty_Factory is Level {
	function createInstance(address _player) public payable override returns (address) {
		_player;
		instance = address(new House());
		return instance;
	}
	
	function validateInstance(address _player) public view override returns (bool) {
		House inst = House(instance);
		return inst.catFound();
	}
}
