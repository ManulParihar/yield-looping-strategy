// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {BaseStrategy} from "tokenized-strategy/BaseStrategy.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {IAavePool} from "../interface/IaavePool.sol";

import {Errors} from "./Errors.sol";

/// @notice Aave Looping Strategy for wstETH/wETH pair
contract YieldLooping is BaseStrategy {

    /// @notice ERC20 token address for wstETH
    /// @dev Lending token
    IERC20 public wstETH;

    /// @notice ERC20 token address for wETH
    /// @dev Borrowing token
    IERC20 public wETH;

    /// @notice Aave pool address
    IAavePool public aavePool;

    constructor(
        address _wstETH,
        address _wETH,
        address _aavePool
    ) BaseStrategy(_wETH, "ynLoopWstETH") {
        require(_wstETH != address(0), Errors.ZeroAddress());
        require(_wETH != address(0), Errors.ZeroAddress());
        require(_aavePool != address(0), Errors.ZeroAddress());

        wstETH = IERC20(_wstETH);
        wETH = IERC20(_wETH);
        aavePool = IAavePool(_aavePool);

        // approve spending of wstETH and wETH
        wstETH.approve(address(aavePool), type(uint256).max);
        wETH.approve(address(aavePool), type(uint256).max);
    }

    function _deployFunds(uint256 _amount) internal override returns (uint256 receivedAmount) {
        require(_amount > 0, Errors.ZeroAmount());

        // Approve spending of wstETH by this vault
        wstETH.approve(address(aavePool), _amount);
        // Send wstETH to Aave
        aavePool.supply(address(wstETH), _amount, address(this), 0);

        uint256 borrowAmount = _calculateBorrow(_amount);
        // interestRateMode is set to 1 (for stable rate of borrowing)
        aavePool.borrow(address(wETH), borrowAmount, 1, 0, address(this));

        // Swap wETH to wstETH for next loop
        receivedAmount = _swap(borrowAmount);
    }

    /// @dev This function calculates the borrow amount based on hardcoded LTV (Loan-To-Value) of 70%
    /// Amount of wETH to be borrowed/received after lending/supplying wstETH
    function _calculateBorrow(uint256 _amount) internal view returns (uint256) {
        return (_amount * 70) / 100;
    }

    /// @dev This function swaps wETH to wstETH
    /// Swaps at 1:1 for simpicity
    function _swap(
        uint256 _amount
    ) internal returns (uint256) {
        return _amount;
    } 
}
