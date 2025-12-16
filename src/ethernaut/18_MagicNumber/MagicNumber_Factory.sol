// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../base/Level.sol";
import {MagicNum} from "./MagicNumber.sol";

contract MagicNumber_Factory is Level {
	function createInstance(address _player) public payable override returns (address) {
		_player; // 消除警告
		
		instance = address(new MagicNum());
		
		return instance;
	}
	
	function validateInstance(address _player) public view override returns (bool) {
		_player; // 消除警告
		
		// Retrieve the instance.
		MagicNum instance = MagicNum(instance);
		
		// Retrieve the solver from the instance.
		Solver solver = Solver(instance.solver());
		
		// Query the solver for the magic number.
		bytes32 magic = solver.whatIsTheMeaningOfLife();
		if (magic != 0x000000000000000000000000000000000000000000000000000000000000002a) return false;
		
		// Require the solver to have at most 10 bytes.
		uint256 size;
		assembly {
			size := extcodesize(solver)
		}
		if (size > 10) return false;
		
		return true;
	}
}

interface Solver {
	function whatIsTheMeaningOfLife() external view returns (bytes32);
}
