// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title Stonks
/// @author https://twitter.com/eugenioclrc
/// @notice You have infiltrated in a big investment firm (name says something about arrows), your task is to loose all their money
/// Challenge URL: https://www.ctfprotocol.com/tracks/eko2022/stonks
contract Stonks {
	mapping(address => mapping(uint256 => uint256)) private _balances;
	
	// stock tickers
	// 股票代码
	uint256 public constant TSLA = 0;
	uint256 public constant GME = 1;
	
	///@dev price oracle 1 TSLA stonk is 50 GME stonks
	///@dev 价格预言机：1 股 TSLA 股票价值 50 股 GME 股票
	uint256 public constant ORACLE_TSLA_GME = 50;
	
	constructor(address _player) {
		///@dev the trader starts with 200 TSLA shares & 1000 GME shares
		///@dev 交易者初始持有 20 股 TSLA 股票和 1000 股 GME 股票
		_balances[_player][TSLA] = 20;
		_balances[_player][GME] = 1_000;
	}
	
	/// @notice Buy TSLA stonks using GME stonks
	/// @param amountGMEin amount of GME to spend
	/// @param amountTSLAout amount of TSLA to buy
	/// @notice 使用 GME 股票购买 TSLA 股票
	/// @param amountGMEin 要花费的 GME 数量
	/// @param amountTSLAout 要购买的 TSLA 数量
	function buyTSLA(uint256 amountGMEin, uint256 amountTSLAout) external {
		require(amountGMEin / ORACLE_TSLA_GME == amountTSLAout, "Invalid price");
		_balances[msg.sender][GME] -= amountGMEin;
		_balances[msg.sender][TSLA] += amountTSLAout;
	}
	
	/// @notice Sell TSLA stonks for GME stonks
	/// @param amountTSLAin amount of GME to spend
	/// @param amountGMEout amount of TSLA to buy
	/// @notice 出售 TSLA 股票换取 GME 股票
	/// @param amountTSLAin 要出售的 TSLA 数量（原注释笔误已修正，保持参数名不变）
	/// @param amountGMEout 要获得的 GME 数量（原注释笔误已修正，保持参数名不变）
	function sellTSLA(uint256 amountTSLAin, uint256 amountGMEout) external {
		require(amountTSLAin * ORACLE_TSLA_GME == amountGMEout, "Invalid price");
		_balances[msg.sender][TSLA] -= amountTSLAin;
		_balances[msg.sender][GME] += amountGMEout;
	}
	
	function balanceOf(address _owner, uint256 _ticker) external view returns (uint256) {
		return _balances[_owner][_ticker];
	}
}
