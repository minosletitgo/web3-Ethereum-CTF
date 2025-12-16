// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../base/Level.sol";
import {Telephone} from "./Telephone.sol";

contract Telephone_Factory is Level {
	function createInstance(address _player) public payable override returns (address) {
		_player; // 消除警告
		
		instance = address(new Telephone());
		
		return instance;
	}
	
	function validateInstance(address _player) public view override returns (bool) {
		_player; // 消除警告
		Telephone inst = Telephone(payable(instance));
		return (inst.owner() == address(_player));
	}
}
