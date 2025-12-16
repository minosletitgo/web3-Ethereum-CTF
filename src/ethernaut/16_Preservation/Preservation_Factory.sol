// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../base/Level.sol";
import {Preservation, LibraryContract} from "./Preservation.sol";

contract Preservation_Factory is Level {
	function createInstance(address _player) public payable override returns (address) {
		_player; // 消除警告
		
		LibraryContract timeZone1 = new LibraryContract();
		LibraryContract timeZone2 = new LibraryContract();
		instance = address(new Preservation(address(timeZone1), address(timeZone2)));
		
		return instance;
	}
	
	function validateInstance(address _player) public view override returns (bool) {
		_player; // 消除警告
		Preservation inst = Preservation(payable(instance));
		return (inst.owner() == address(_player));
	}
}
