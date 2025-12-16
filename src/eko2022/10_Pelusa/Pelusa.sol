// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IGame {
	function getBallPossesion() external view returns (address);
}

// "el baile de la gambeta"
// "盘带之舞"（即“胯下过人”技巧）
// https://www.youtube.com/watch?v=qzxn85zX2aE

/// @title Pelusa（意为“绒毛”，这里指马拉多纳的昵称或灵动球风）
/// @author https://twitter.com/eugenioclrc
/// @notice Its 1986, you are in the football world cup (Mexico86), help Diego score a goal.
/// Challenge URL: https://www.ctfprotocol.com/tracks/eko2022/pelusa
contract Pelusa {
	address private immutable owner;
	
	address internal player;
	
	uint256 public goals = 1;
	
	constructor() {
		owner = address(uint160(uint256(keccak256(abi.encodePacked(msg.sender, blockhash(block.number))))));
	}
	
	function passTheBall() external {
		require(msg.sender.code.length == 0, "Only EOA players");
		/// @dev "la pelota siempre al 10"
		/// @dev "球始终要传给10号"
		require(uint256(uint160(msg.sender)) % 100 == 10, "not allowed");
		
		player = msg.sender;
	}
	
	function isGoal() public view returns (bool) {
		// expect ball in owners posession
		// 预期球在拥有者手中
		return IGame(player).getBallPossesion() == owner;
	}
	
	function shoot() external {
		require(isGoal(), "missed");
		/// @dev use "the hand of god" trick
		/// @dev 使用“上帝之手”技巧
		(bool success, bytes memory data) = player.delegatecall(abi.encodeWithSignature("handOfGod()"));
		require(success, "missed");
		require(uint256(bytes32(data)) == 22_06_1986);
	}
}
