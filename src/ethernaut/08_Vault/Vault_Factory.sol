// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../base/Level.sol";
import {Vault} from "./Vault.sol";

contract Vault_Factory is Level {
	function createInstance(address _player) public payable override returns (address) {
		_player; // 消除警告
		
		instance = address(new Vault(bytes32(uint256(9527))));
		
		return instance;
	}
	
	function validateInstance(address _player) public view override returns (bool) {
		_player; // 消除警告
		Vault inst = Vault(payable(instance));
		return (inst.locked() == false);
	}
}
