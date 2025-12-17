// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {EllipticToken} from "../../src/ethernaut/35_EllipticToken/EllipticToken.sol";
import {EllipticToken_Factory} from "../../src/ethernaut/35_EllipticToken/EllipticToken_Factory.sol";
import {EllipticToken_Attacker} from "./35_EllipticToken_Attacker.sol";

contract EllipticToken_Test is Test {
	address deployer = makeAddr("deployer");
	
	uint256 playerPrivateKey = 0x123456789;
	address player = vm.addr(playerPrivateKey); // 从私钥推导地址

	EllipticToken_Factory factory;
	EllipticToken instContract;
	
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
		
		factory = new EllipticToken_Factory();
		instContract = EllipticToken(payable(factory.createInstance(player)));
		
		vm.stopPrank();
	}
	
	function test__Solution_EllipticToken() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_EllipticToken -vv
		
		// 涉及到`椭圆曲线算法`原型。
		// 参阅`分析(EEexplorer001)-CN.md`。。。
		
		EllipticToken ellipticToken = EllipticToken(instContract);
		
		address bob = 0xB0B14927389CB009E0aabedC271AC29320156Eb8;
		address alice = 0xA11CE84AcB91Ac59B0A4E2945C9157eF3Ab17D4e;
		uint256 INITIAL_AMOUNT = 10 ether;
		
		address tokenOwner = alice;
		
		uint256 amount = uint256(0x1176ea0c3e05d106665d9ce306359578b32fd2441e7234a6f1cc2218676f346a);
		bytes memory tokenOwnerSignature =
					hex"aba231ba9cb786c65abe725bcf4785b2db4825d8506a3c493fa3edab685d6ee86249c4f865276652d8e2dbcf1957ffacd21a1635b993286f9a1fefd1afe24fae1c";
		bytes32 permitAcceptHash = keccak256(abi.encodePacked(tokenOwner, player, amount));
		(uint8 v, bytes32 r, bytes32 s) = vm.sign(playerPrivateKey, permitAcceptHash);
		bytes memory spenderSignature = abi.encodePacked(r, s, v);
		
		ellipticToken.permit(amount, player, tokenOwnerSignature, spenderSignature);
		
		uint256 amount_tokenOwner = ellipticToken.balanceOf(tokenOwner);
		bool success = ellipticToken.transferFrom(tokenOwner, player, amount_tokenOwner);
		require(success, "Transfer failed");
		
		console.log("Alice's ETK balance:", ellipticToken.balanceOf(tokenOwner));
	}
}
