// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Forta, CryptoVault, LegacyToken, DoubleEntryPoint, DelegateERC20, IDetectionBot, IForta} from "../../src/ethernaut/26_DoubleEntryPoint/DoubleEntryPoint.sol";

contract DoubleEntryPoint_Attacker {
	address player;
	CryptoVault cryptoVault;
	Forta forta;
	
	constructor(CryptoVault cryptoVault_, Forta forta_) payable {
		player = msg.sender;
		cryptoVault = cryptoVault_;
		forta = forta_;
	}
	
	receive() external payable {}
	
	function handleTransaction(address user, bytes calldata msgData) external {
		require(user == player);
		// handleTransaction(address,bytes) -> 220ab6aa896583d843c5b050679e00fd25389fcb741b7e3445a71831bb2a6283
		console.logBytes(msgData);
		// !!!---> delegateTransfer(address,uint256,address) // 9cd1a1211670344edaaf7bd8870bf83bfb7b31a93c51b25e35de130796af11ee
		// !!!---> console.logBytes4(DoubleEntryPoint.delegateTransfer.selector); // 0x9cd1a121
		
		// 0x9cd1a121000000000000000000000000ae0bdc4eeac5e950b67c6819b118761caaf619460000000000000000000000000000000000000000000000056bc75e2d631000000000000000000000000000001240fa2a84dd9157a0e76b5cfe98b1d52268b264
		//
		// 9cd1a121
		// 000000000000000000000000ae0bdc4eeac5e950b67c6819b118761caaf61946 // deployer
		// 0000000000000000000000000000000000000000000000056bc75e2d63100000 // 100 ether
		// 0000000000000000000000001240fa2a84dd9157a0e76b5cfe98b1d52268b264 // address(CryptoVault)
		
		(,, address from) = abi.decode(msgData[4:], (address, uint256, address));
		if (from == address(cryptoVault)) {
			// 严格意义，需要补充"如果，是从清扫函数发出的(即，发起者是金库)"
			forta.raiseAlert(address(player));
		}
	}
}
