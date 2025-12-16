// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../base/Level.sol";
import {GatekeeperOne} from "./GatekeeperOne.sol";

contract GatekeeperOne_Factory is Level {
	function createInstance(address _player) public payable override returns (address) {
		_player; // 消除警告
		
		instance = address(new GatekeeperOne());
		
		return instance;
	}
	
	function validateInstance(address _player) public view override returns (bool) {
		_player; // 消除警告
		GatekeeperOne inst = GatekeeperOne(payable(instance));
		return (inst.entrant() == address(_player));
	}
}
