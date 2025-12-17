// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../base/Level.sol";
import {Impersonator, ECLocker} from "./Impersonator.sol";

contract Impersonator_Factory is Level {
	function createInstance(address _player) public payable override returns (address) {
		_player; // 消除警告
		
		Impersonator impersonator = new Impersonator(1);
		bytes memory signature = abi.encode(
			[
				uint256(0x08df0e0cb1e3d74c28284b28c5f729a2777cbc1e43b5a0457e76e127db5a202f),
				uint256(0x0c21d0cf89c7eaf7eefcf347fbab412269e434623adb609345969a919e92474f),
				uint256(0x000000000000000000000000000000000000000000000000000000000000001c)
			]
		);
		impersonator.deployNewLock(signature);
		
		instance = address(impersonator);
		
		return instance;
	}
	
	function validateInstance(address _player) public view override returns (bool) {
		_player; // 消除警告
		Impersonator inst = Impersonator(payable(instance));
		ECLocker locker = inst.lockers(0);
		return (locker.controller() == address(0));
	}
}
