// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../base/Level.sol";
import {Reentrance} from "./Reentrance.sol";

contract Reentrance_Factory is Level {
	function createInstance(address _player) public payable override returns (address) {
		_player; // 消除警告
		
		require(msg.value >= 10);
		
		instance = address(new Reentrance());
		address(instance).call{value: msg.value}("");
		
		return instance;
	}
	
	function validateInstance(address _player) public view override returns (bool) {
		_player; // 消除警告
		Reentrance inst = Reentrance(payable(instance));
		return (address(inst).balance == 0);
	}
}
