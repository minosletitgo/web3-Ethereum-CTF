// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../base/Level.sol";
import {Delegate, Delegation} from "./Delegate.sol";

contract Delegate_Factory is Level {
	function createInstance(address _player) public payable override returns (address) {
		_player; // 消除警告
		
		Delegate delegateContract = new Delegate(address(this));
		instance = address(new Delegation(address(delegateContract)));
		
		return instance;
	}
	
	function validateInstance(address _player) public view override returns (bool) {
		_player; // 消除警告
		Delegation inst = Delegation(payable(instance));
		return (inst.owner() == address(_player));
	}
}
