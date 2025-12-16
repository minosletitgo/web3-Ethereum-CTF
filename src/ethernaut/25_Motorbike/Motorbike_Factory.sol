// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../base/Level.sol";
import {Motorbike, Engine} from "./Motorbike.sol";
import "../helpers/Address.sol";

contract Motorbike_Factory is Level {
	address engineAddress;
	function createInstance(address _player) public payable override returns (address) {
		_player; // 消除警告
		
		// 部署`原始的逻辑合约`
		Engine engine = new Engine();
		// 部署`代理合约`
		Motorbike motorbike = new Motorbike(address(engine));
		// 取得 代理合约的嵌套合约
		Engine engineAsProxy = Engine(address(motorbike));
		
		instance = address(engineAsProxy);
		engineAddress = address(engine);
		
		return instance;
	}
	
	function validateInstance(address _player) public view override returns (bool) {
		_player; // 消除警告
		
		return !Address.isContract(engineAddress);
	}
}
