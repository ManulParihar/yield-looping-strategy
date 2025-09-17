// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/src/Test.sol";
import {YieldLooping} from "../src/contracts/YieldLooping.sol";
import {MockERC20} from "./mock/MockERC20.sol";
import {MockAavePool} from "./mock/MockAavePool.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

contract YieldLoopingTest is Test {
    YieldLooping public strategy;
    MockERC20 public wstETH;
    MockERC20 public wETH;
    MockAavePool public aavePool;

    function setUp() public {
        // Deploy mocks
        wstETH = new MockERC20("Wrapped Staked ETH", "wstETH");
        wETH = new MockERC20("Wrapped ETH", "wETH");
        aavePool = new MockAavePool(address(wstETH), address(wETH));

        // Deploy strategy
        strategy = new YieldLooping(
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

        // Call deployFunds via a prank so msg.sender == strategy
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
}
