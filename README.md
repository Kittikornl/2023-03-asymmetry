# ISSUE

- function ethPerDerivative(uint) of reth can be manipulated: attacker can deposit just enough to mint reth with rocketDepositPool but using uniswap pool rate to calculate mint share in function stake (SafETH contract)
- uniswap pool rate using spot price which can be manipulated (can be a problem if pool has low liquidity)

# POC

- set reth getMaximumDepositPoolSize to 5400 eth
- richman stake to protocol 200 eth
- attacker stake 200 eth to protocol (200 eth will mint @rocketDepositPool) and mint share with higher rate (uniswap pool rate)
- attacker unstake all share from protocol

# What happen when attacker stake just enough amount to be able to mint with rocketDepositPool

- https://github.com/code-423n4/2023-03-asymmetry/blob/main/contracts/SafEth/SafEth.sol#L73 using rate from https://github.com/code-423n4/2023-03-asymmetry/blob/main/contracts/SafEth/derivatives/Reth.sol#L214 since we have enough amount to mint with rocketDepositPool
- https://github.com/code-423n4/2023-03-asymmetry/blob/main/contracts/SafEth/derivatives/Reth.sol#L198 mint new reth from rocketDepositPool in this step will update rocketDepositPool.getBalance() (https://github.com/code-423n4/2023-03-asymmetry/blob/main/contracts/SafEth/derivatives/Reth.sol#L147) and make poolCanDeposit(x) alway returns false; x > 0
- https://github.com/code-423n4/2023-03-asymmetry/blob/main/contracts/SafEth/SafEth.sol#L92 using rate from uniswap spot price (https://github.com/code-423n4/2023-03-asymmetry/blob/main/contracts/SafEth/derivatives/Reth.sol#L215)
- note: uniswap spot price can be an issue if pool have low liquidity

# command to run

forge test -f {MAINNET-RPC} -vvvv

# result

![](https://imgur.com/qiGqKRr.jpg)
