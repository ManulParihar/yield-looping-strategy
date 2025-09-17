// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/src/Test.sol";
import {MockERC20} from "./mock/MockERC20.sol";
import {MockAavePool} from "./mock/MockAavePool.sol";
import {MockYieldLooping} from "./mock/MockYieldLooping.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

contract YieldLoopingTest is Test {
    MockYieldLooping public strategy;
    MockERC20 public wstETH;
    MockERC20 public wETH;
    MockAavePool public aavePool;

    function setUp() public {
        // Deploy mocks
        wstETH = new MockERC20("Wrapped Staked ETH", "wstETH");
        wETH = new MockERC20("Wrapped ETH", "wETH");
        aavePool = new MockAavePool(address(wstETH), address(wETH));

        // Deploy strategy
        strategy = new MockYieldLooping(
            address(wstETH),
            address(wETH),
            address(aavePool)
        );

        // Mint initial tokens to strategy
        wstETH.mint(address(strategy), 100 ether);
        wETH.mint(address(strategy), 100 ether);
    }

    function testDeployFundsLoop() public {
        uint256 depositAmount = 10 ether;

        vm.prank(address(strategy));
        strategy.deployFunds(depositAmount);

        // MAX_LOOP = 3, borrow at 70% each loop:
        // 1st loop: 10 supply -> 7 borrow -> 7 swapped
        // 2nd loop: 7 supply -> 4.9 borrow -> 4.9 swapped
        // 3rd loop: 4.9 supply -> 3.43 borrow -> 3.43 swapped
        uint256 expectedCollateral = 10 ether + 7 ether + 4.9 ether; // total supplied
        uint256 expectedDebt = 7 ether + 4.9 ether + 3.43 ether; // total debt

        // Check AavePool balances
        uint256 actualCollateral = aavePool.supplied(address(wstETH), address(strategy));
        uint256 actualDebt = aavePool.debt(address(wETH), address(strategy));

        assertApproxEqAbs(actualCollateral, expectedCollateral, 0.01 ether);
        assertApproxEqAbs(actualDebt, expectedDebt, 0.01 ether);
    }

    function testTotalValue() public {
        uint256 depositAmount = 10 ether;

        vm.prank(address(strategy));
        strategy.deployFunds(depositAmount);

        vm.prank(address(strategy));
        uint256 total = strategy.totalValue();

        uint256 collateral;
        uint256 debt;
        (collateral, debt,,,,) = aavePool.getUserAccountData(address(strategy));

        uint256 unusedBalance = wstETH.balanceOf(address(strategy));
        uint256 wstETHPrice = strategy.getAssetPrice(address(wstETH));
        uint256 wstETHValue = (unusedBalance * wstETHPrice) / 1e18;

        collateral += wstETHValue;

        uint256 expectedTotal;
        if(collateral > debt) {
            expectedTotal = collateral - debt;
        } else {
            expectedTotal = 0;
        }

        assertApproxEqAbs(total, expectedTotal, 1e16);
    }
}
