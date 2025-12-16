// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../base/Level.sol";
import {Shop} from "./Shop.sol";

contract Shop_Factory is Level {
	uint256 shopOldPrice;
	
	function createInstance(address _player) public payable override returns (address) {
		_player; // 消除警告
		
		instance = address(new Shop());
		shopOldPrice = Shop(instance).price();
		
		return instance;
	}
	
	function validateInstance(address _player) public view override returns (bool) {
		_player; // 消除警告
		Shop inst = Shop(payable(instance));
		return (inst.price() < shopOldPrice);
	}
}
