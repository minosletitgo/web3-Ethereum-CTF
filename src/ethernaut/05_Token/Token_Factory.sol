// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../base/Level.sol";
import {Token} from "./Token.sol";

contract Token_Factory is Level {
	function createInstance(address _player) public payable override returns (address) {
		_player; // 消除警告
		
		instance = address(new Token(_player));
		
		return instance;
	}
	
	function validateInstance(address _player) public view override returns (bool) {
		_player; // 消除警告
		Token inst = Token(payable(instance));
		return (inst.balanceOf(_player) >= inst.totalSupply());
	}
}
