// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../base/Level.sol";
import {MagicAnimalCarousel} from "./MagicAnimalCarousel.sol";

contract MagicAnimalCarousel_Factory is Level {
	function createInstance(address _player) public payable override returns (address) {
		_player; // 消除警告
		
		instance = address(new MagicAnimalCarousel());
		
		return instance;
	}
	
	function validateInstance(address _player) public override returns (bool) {
		_player; // 消除警告
		MagicAnimalCarousel inst = MagicAnimalCarousel(payable(instance));
		
		string memory newName = "A New Name!!";
		inst.setAnimalAndSpin(newName);
		uint256 currentCrateId = inst.currentCrateId();
		uint256 animalNameInBox = inst.carousel(currentCrateId) >> 176;
		uint256 newNameEncode = uint256(bytes32(abi.encodePacked(newName))) >> 176;
		if (animalNameInBox != newNameEncode) {
			return true;
		}
		return false;
	}
}
