// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract MockAavePool {
    
    // asset <> to <> amount
    mapping(address => mapping(address => uint256)) public supplied;
    // asset <> to <> amount (debt received by "to")
    mapping(address => mapping(address => uint256)) public debt;

    address public wstETH;
    address public wETH;

    constructor(address _wstETH, address _wETH) {
        require(_wstETH != address(0) && _wETH != address(0), "Zero address");
        wstETH = _wstETH;
        wETH = _wETH;
    }

    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external {
        supplied[asset][onBehalfOf] += amount;
    }

    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external {
        debt[asset][onBehalfOf] += amount;
    }

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external {
        require(supplied[asset][to] >= amount, "Not enough balance");
        supplied[asset][to] -= amount;
    }

    function getUserAccountData(address user) external view returns (
        uint256 totalCollateralBase,
        uint256 totalDebtBase,
        uint256 availableBorrowsBase,
        uint256 currentLiquidationThreshold,
        uint256 ltv,
        uint256 healthFactor
    ) {
        // For simplicity, assuming 1:1 price in ETH
        totalCollateralBase = supplied[wstETH][user];
        totalDebtBase = debt[wETH][user];

        // User can borrow up to 70% of collateral minus debt
        availableBorrowsBase = (totalCollateralBase * 70 / 100) - totalDebtBase;

        // LTV is 70% as hardcoded in YieldLooping.sol
        // In Aave (100% => 10000)
        ltv = 7000;

        // Dummy values
        currentLiquidationThreshold = 0;
        healthFactor = 0;
    }
}
