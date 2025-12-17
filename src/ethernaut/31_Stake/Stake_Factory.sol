// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../base/Level.sol";
import {Stake} from "./Stake.sol";
import {WETH9} from "../helpers/WETH9.sol";

contract Stake_Factory is Level {
	function createInstance(address _player) public payable override returns (address) {
		_player; // 消除警告
		
		WETH9 wethContract = new WETH9();
		Stake stakeContract = new Stake{value: 100 ether}(address(wethContract));
		
		instance = address(stakeContract);
		
		return instance;
	}
	
	function validateInstance(address _player) public view override returns (bool) {
		_player; // 消除警告
		Stake inst = Stake(payable(instance));
		return instance.balance != 0 && inst.totalStaked() > instance.balance && inst.UserStake(_player) == 0 && inst.Stakers(_player);
	}
}
