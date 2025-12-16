// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../base/Level.sol";
import {PuzzleWallet, PuzzleProxy} from "./PuzzleWallet.sol";

contract PuzzleWallet_Factory is Level {
	
	function createInstance(address _player) public payable override returns (address) {
		_player; // 消除警告
		
		// 部署逻辑合约
		PuzzleWallet puzzleWallet = new PuzzleWallet();
		
		// 部署代理合约，且初始化数据
		bytes memory data = abi.encodeWithSelector(PuzzleWallet.init.selector, 100 ether);
		PuzzleProxy	puzzleProxy = new PuzzleProxy(address(this), address(puzzleWallet), data);
		
		// 把代理合约包装为逻辑合约
		PuzzleWallet puzzleWalletAsProxy = PuzzleWallet(address(puzzleProxy));
		// 把 deployer 加入白名单
		puzzleWalletAsProxy.addToWhitelist(address(this));
		// 存入资金，即，钱包已填满
		puzzleWalletAsProxy.deposit{value: msg.value}();
		
		instance = address(puzzleProxy);
		return instance;
	}
	
	function validateInstance(address _player) public view override returns (bool) {
		_player; // 消除警告
		PuzzleProxy inst = PuzzleProxy(payable(instance));
		return (inst.admin() == address(_player));
	}
}
