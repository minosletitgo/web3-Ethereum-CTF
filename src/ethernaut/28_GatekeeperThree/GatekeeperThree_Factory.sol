// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../base/Level.sol";
import {GatekeeperThree} from "./GatekeeperThree.sol";

contract GatekeeperThree_Factory is Level {
	function createInstance(address _player) public payable override returns (address) {
		_player; // 消除警告
		
		instance = address(new GatekeeperThree());
		GatekeeperThree(payable(address(instance))).createTrick();
		
		return instance;
	}
	
	function validateInstance(address _player) public view override returns (bool) {
		_player; // 消除警告
		GatekeeperThree inst = GatekeeperThree(payable(address(instance)));
		return (inst.entrant() == address(_player));
	}
}
