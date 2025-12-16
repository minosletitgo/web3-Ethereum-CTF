// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../base/Level.sol";
import {Recovery, SimpleToken} from "./Recovery.sol";

contract Recovery_Factory is Level {
	address lostAddress;
	
	function createInstance(address _player) public payable override returns (address) {
		_player; // 消除警告
		
		require(msg.value >= 0.001 ether);
		
		instance = address(new Recovery());
		
		Recovery(instance).generateToken("ST", 1000 ether);
		
		// 更标准的 CREATE 地址计算
		lostAddress = address(uint160(uint256(keccak256(abi.encodePacked(
			bytes1(0xd6),  // RLP 长度前缀
			bytes1(0x94),  // 20字节地址 + 1字节 nonce 的总长度
			instance,
			bytes1(0x01)   // nonce
		)))));
		
		lostAddress.call{value: 0.001 ether}("");
		
		return instance;
	}
	
	function validateInstance(address _player) public view override returns (bool) {
		_player; // 消除警告
		return (address(lostAddress).balance == 0);
	}
}
