// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../base/Level.sol";
import {Privacy} from "./Privacy.sol";

contract Privacy_Factory is Level {
	function createInstance(address _player) public payable override returns (address) {
		_player; // 消除警告
		
		bytes32[3] memory data;
		data[0] = bytes32(uint256(uint256(9527)));
		data[1] = bytes32(uint256(uint256(9537)));
		data[2] = bytes32(uint256(uint256(9547)));
		
		instance = address(new Privacy(data));
		
		return instance;
	}
	
	function validateInstance(address _player) public view override returns (bool) {
		_player; // 消除警告
		Privacy inst = Privacy(payable(instance));
		return (inst.locked() == false);
	}
}
