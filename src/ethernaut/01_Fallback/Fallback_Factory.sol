// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../base/Level.sol";
import {Fallback} from "./Fallback.sol";

contract Fallback_Factory is Level {
	function createInstance(address _player) public payable override returns (address) {
		_player; // 消除警告
		
		instance = address(new Fallback());
		
		return instance;
	}
	
	function validateInstance(address _player) public view override returns (bool) {
		_player; // 消除警告
		Fallback inst = Fallback(payable(instance));
		return (inst.owner() == address(_player) && address(inst).balance == 0);
	}
}
