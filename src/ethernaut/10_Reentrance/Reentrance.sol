// SPDX-License-Identifier: MIT
//pragma solidity ^0.6.12;
pragma solidity ^0.8.24;

// 由于0.8.0之后的版本，已经内置溢出检查，故，本代码中，摒弃相关依赖库(因为，不方便引入)。
//import "openzeppelin-contracts-06/math/SafeMath.sol";

contract Reentrance {
	//using SafeMath for uint256;
	
	mapping(address => uint256) public balances;
	
	function donate(address _to) public payable {
		//balances[_to] = balances[_to].add(msg.value);
		balances[_to] += msg.value; // 为了模拟在0.8.0之前的旧版本，必须这样改动，否则，无法调挑战。
	}
	
	function balanceOf(address _who) public view returns (uint256 balance) {
		return balances[_who];
	}
	
	function withdraw(uint256 _amount) public {
		if (balances[msg.sender] >= _amount) {
			(bool result,) = msg.sender.call{value: _amount}("");
			if (result) {
				_amount;
			}
			
			//balances[msg.sender] -= _amount;
			unchecked {
				balances[msg.sender] -= _amount; // 为了模拟在0.8.0之前的旧版本，必须这样改动，否则，无法调挑战。
			}
		}
	}
	
	receive() external payable {}
}
