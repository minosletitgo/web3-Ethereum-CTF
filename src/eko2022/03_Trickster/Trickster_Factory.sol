// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../base/Level.sol";
import {Jackpot, JackpotProxy} from "./Trickster.sol";

contract Trickster_Factory is Level {
	uint256 initBalanceOfPlayer;
	uint256 initBalanceOfJackpotProxy;
	
	function createInstance(address _player) public payable override returns (address) {
		_player; // 消除警告
		
		require(msg.value > 0);
		require(_player.balance > 0);
		
		instance = address(new JackpotProxy{value: msg.value}());
		
		initBalanceOfPlayer = _player.balance;
		initBalanceOfJackpotProxy = instance.balance;
		
		return instance;
	}
	
	function validateInstance(address _player) public view override returns (bool) {
		_player; // 消除警告
		
		return (_player.balance == initBalanceOfPlayer + initBalanceOfJackpotProxy);
	}
}
