// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Level is Ownable {
	address public instance;
	
	constructor() Ownable(msg.sender) {}
	
	function createInstance(address _player) public payable virtual returns (address);
	function validateInstance(address _player) public virtual returns (bool);
}
