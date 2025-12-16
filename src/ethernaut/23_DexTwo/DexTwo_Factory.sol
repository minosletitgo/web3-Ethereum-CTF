// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../base/Level.sol";
import {DexTwo, SwappableTokenTwo} from "./DexTwo.sol";

contract DexTwo_Factory is Level {
	function createInstance(address _player) public payable override returns (address) {
		_player; // 消除警告
		
		instance = address(new DexTwo());
		
		// 管理员新部署token1、token2
		uint256 initAmountToken = 10000 ether;
		SwappableTokenTwo token1 = new SwappableTokenTwo(address(instance),"TK1", "TK1", initAmountToken);
		SwappableTokenTwo token2 = new SwappableTokenTwo(address(instance),"TK2", "TK2", initAmountToken);
		
		// 管理员让Dex初始拥有token1、token2各自 100个
		uint256 initDexAmountToken = 100 ether;
		DexTwo(instance).setTokens(address(token1), address(token2));
		DexTwo(instance).approve(address(instance),initDexAmountToken);
		DexTwo(instance).add_liquidity(address(token1), initDexAmountToken);
		DexTwo(instance).add_liquidity(address(token2), initDexAmountToken);
		
		// 发放给玩家 各自 10 个
		uint256 initPlayerAmountToken = 10 ether;
		token1.transfer(_player, initPlayerAmountToken);
		token2.transfer(_player, initPlayerAmountToken);
		
		return instance;
	}
	
	function validateInstance(address _player) public view override returns (bool) {
		_player; // 消除警告
		DexTwo inst = DexTwo(payable(instance));
		
		uint256 amountCurrentToken1 = inst.balanceOf(address(inst.token1()), address(instance));
		uint256 amountCurrentToken2 = inst.balanceOf(address(inst.token2()), address(instance));
		if (amountCurrentToken1 == 0 && amountCurrentToken2 == 0) {
			return true;
		} else {
			return false;
		}
	}
}
