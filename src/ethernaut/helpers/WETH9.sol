// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title WETH9 - Wrapped Ether (compatible with mainnet WETH9)
 * @dev ERC-20 token that represents wrapped Ether on Ethereum
 * Compatible with the interface used on Ethereum mainnet
 */
contract WETH9 {
	// Token metadata
	string public name     = "Wrapped Ether";
	string public symbol   = "WETH";
	uint8  public decimals = 18;
	
	// Events (matching mainnet WETH9 interface)
	event  Approval(address indexed src, address indexed guy, uint wad);
	event  Transfer(address indexed src, address indexed dst, uint wad);
	event  Deposit(address indexed dst, uint wad);
	event  Withdrawal(address indexed src, uint wad);
	
	// State variables (public like mainnet WETH9)
	mapping (address => uint)                       public  balanceOf;
	mapping (address => mapping (address => uint))  public  allowance;
	
	/**
	 * @dev Fallback function - calls deposit() when receiving ETH
     * Matches mainnet WETH9 behavior
     */
	fallback() external payable {
		deposit();
	}
	
	/**
	 * @dev Receive function for plain ETH transfers
     * Matches mainnet WETH9 behavior
     */
	receive() external payable {
		deposit();
	}
	
	/**
	 * @dev Deposit ETH and mint WETH
     * Matches mainnet WETH9 interface
     */
	function deposit() public payable {
		balanceOf[msg.sender] += msg.value;
		emit Deposit(msg.sender, msg.value);
	}
	
	/**
	 * @dev Withdraw ETH by burning WETH
     * Matches mainnet WETH9 interface
     * @param wad Amount of WETH to withdraw (in wei)
     */
	function withdraw(uint wad) public {
		require(balanceOf[msg.sender] >= wad, "WETH9: insufficient balance");
		
		balanceOf[msg.sender] -= wad;
		payable(msg.sender).transfer(wad);
		emit Withdrawal(msg.sender, wad);
	}
	
	/**
	 * @dev Get total supply of WETH (total ETH locked in contract)
     * Matches mainnet WETH9 interface - uses this.balance
     * @return Total supply in wei
     */
	function totalSupply() public view returns (uint) {
		return address(this).balance;
	}
	
	/**
	 * @dev Approve spender to transfer tokens
     * Matches mainnet WETH9 interface - returns bool
     * @param guy Address to approve
     * @param wad Amount to approve
     * @return Always returns true
     */
	function approve(address guy, uint wad) public returns (bool) {
		allowance[msg.sender][guy] = wad;
		emit Approval(msg.sender, guy, wad);
		return true;
	}
	
	/**
	 * @dev Transfer tokens (calls transferFrom internally)
     * Matches mainnet WETH9 interface - returns bool
     * @param dst Destination address
     * @param wad Amount to transfer
     * @return Always returns true
     */
	function transfer(address dst, uint wad) public returns (bool) {
		return transferFrom(msg.sender, dst, wad);
	}
	
	/**
	 * @dev Transfer tokens from source to destination
     * Matches mainnet WETH9 interface including the uint(-1) check for unlimited approval
     * @param src Source address
     * @param dst Destination address
     * @param wad Amount to transfer
     * @return Always returns true
     */
	function transferFrom(address src, address dst, uint wad) public returns (bool) {
		require(balanceOf[src] >= wad, "WETH9: insufficient balance");
		
		if (src != msg.sender && allowance[src][msg.sender] != type(uint).max) {
			require(allowance[src][msg.sender] >= wad, "WETH9: insufficient allowance");
			allowance[src][msg.sender] -= wad;
		}
		
		balanceOf[src] -= wad;
		balanceOf[dst] += wad;
		
		emit Transfer(src, dst, wad);
		
		return true;
	}
}
