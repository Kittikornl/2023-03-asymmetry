# ISSUE

- function ethPerDerivative(uint) of reth can be manipulated: attacker can deposit just enough to mint reth with rocketDepositPool but using uniswap pool rate to calculate mint share in function stake (SafETH contract)
- uniswap pool rate using spot price which can be manipulated (can be a problem if pool has low liquidity)

# POC

- set reth getMaximumDepositPoolSize to 5400 eth
- richman stake to protocol 200 eth
- attacker stake 200 eth to protocol (200 eth will mint @rocketDepositPool) and mint share with higher rate (uniswap pool rate)
- attacker unstake all share from protocol

# command to run

forge test -f {MAINNET-RPC} -vvvv

# result

![](https://imgur.com/qiGqKRr.jpg)
