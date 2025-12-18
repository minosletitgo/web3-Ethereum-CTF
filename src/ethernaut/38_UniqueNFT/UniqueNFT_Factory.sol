// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../base/Level.sol";
import {UniqueNFT} from "./UniqueNFT.sol";

contract UniqueNFT_Factory is Level {
	function createInstance(address _player) public payable override returns (address) {
		_player; // 消除警告
		
		instance = address(new UniqueNFT());
		
		return instance;
	}
	
	function validateInstance(address _player) public view override returns (bool) {
		_player; // 消除警告
		UniqueNFT inst = UniqueNFT(payable(instance));
		return (inst.balanceOf(_player) > 1);
	}
}
