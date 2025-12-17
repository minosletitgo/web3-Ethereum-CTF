// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../base/Level.sol";
import {Forta, CryptoVault, LegacyToken, DoubleEntryPoint, DelegateERC20, IDetectionBot, IForta} from "./DoubleEntryPoint.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DoubleEntryPoint_Factory is Level {
	Forta public forta;
	CryptoVault public cryptoVault;
	LegacyToken public legacyToken;
	DoubleEntryPoint public doubleEntryPoint;
	
	function createInstance(address _player) public payable override returns (address) {
		_player; // 消除警告
		
		forta = new Forta();
		cryptoVault = new CryptoVault(address(this));
		legacyToken = new LegacyToken();
		doubleEntryPoint = new DoubleEntryPoint(address(legacyToken), address(cryptoVault), address(forta), address(_player));
		cryptoVault.setUnderlying(address(doubleEntryPoint));
		legacyToken.delegateToNewContract(DelegateERC20(address(doubleEntryPoint)));
		
		legacyToken.mint(address(cryptoVault), 100 ether);
		
		return address(cryptoVault);
	}
	
	function validateInstance(address _player) public override returns (bool) {
		_player; // 消除警告
		
		try cryptoVault.sweepToken(IERC20(address(legacyToken))) {
			return false;
		} catch Error(string memory reason) {
			// 只能捕获 revert/require 的字符串错误
			if (keccak256(abi.encodePacked(reason)) == keccak256(abi.encodePacked("Alert has been triggered, reverting"))) {
				return true;
			} else {
				return false;
			}
		} catch Panic(uint errorCode) {
			return false;
		} catch (bytes memory lowLevelData) {
			return false;
		}
	}
}
