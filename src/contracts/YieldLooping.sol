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

    uint256 public constant MAX_LOOP = 3;

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
    }

    /// @notice This is underlying logic which will be used for looping
    /// @dev Implements BaseStrategy._deployFunds
    function _deployFunds(uint256 _amount) internal override returns (uint256 receivedAmount) {
        require(_amount > 0, Errors.ZeroAmount());

        uint256 suppliedAmount = _amount;
        receivedAmount = 0;

        for(uint256 i=0; i<MAX_LOOP; ++i) {
            // Approve spending of wstETH by this vault
            wstETH.approve(address(aavePool), suppliedAmount);
            // Send wstETH to Aave
            aavePool.supply(address(wstETH), suppliedAmount, address(this), 0);

            uint256 borrowAmount = _calculateBorrow(suppliedAmount);
            // interestRateMode is set to 1 (for stable rate of borrowing)
            aavePool.borrow(address(wETH), borrowAmount, 1, 0, address(this));

            // Swap wETH to wstETH for next loop
            uint256 swappedAmount = _swap(borrowAmount);

            receivedAmount += swappedAmount;
            // update supply for next loop
            suppliedAmount = swappedAmount;
        }
    }

    /// @notice This function withdraws wstETH from the Aave
    /// @dev Implements BaseStrategy._freeFunds
    function _freeFunds(_amount) internal override {
        require(_amount > 0, Errors.ZeroAmount());
        aavePool.withdraw(address(wstETH), _amount, address(this));
    }

    /// @notice This calculates the total value of wETH in holding
    /// @dev Implements BaseStrategy._harvestAndReport
    function _harvestAndReport() internal override returns (uint256) {
        return _totalValue();
    }

    function _totalValue() internal view returns (uint256) {
        // Amount of wETH (supplied to Aave + wallet balance - debt)

        // Amount deposited in Aave
        (uint256 collateralBase, uint256 debtBase,,,,) = aavePool.getUserAccountData(address(this));

        // Unused wstETH in this vault
        uint256 unusedWstETHBalance = wstETH.balanceOf(address(this));

        if(unusedWstETHBalance > 0) {
            // TODO: add oracle to fetch wstETH price
            uint256 wstETHPrice = _getAssetPrice(address(wstETH));
            // Value of wstETH (in terms of ETH) present in this vault
            uint256 wstETHValue = (unusedWstETHBalance * wstETHPrice) / 1e18;
            // collaterlBase is already priced in ETH.
            collateralBase += wstETHValue;
        }

        if(collateralBase > debtBase) {
            // collateral value in ETH - debt value in ETH
            return collateralBase - debtBase;
        } else {
            return 0;
        }
    }

    /// @notice Calculates the rate of ynLoopWstETH vault token
    function getVaultRate() external view returns (uin256) {
        uint256 totalSupply = IERC20(address(this)).totalSupply();

        if(totalSupply == 0) {
            return 0;
        }
        
        // _totalValue is the value this vault holds
        return (_totalValue() * 1e18) / totalSupply;
    }

    /// @dev This function calculates the borrow amount based on hardcoded LTV (Loan-To-Value) of 70%
    /// Amount of wETH to be borrowed/received after lending/supplying wstETH
    /// TODO: Use Aave's LTV
    function _calculateBorrow(uint256 _amount) internal view returns (uint256) {
        return (_amount * 70) / 100;
    }

    /// @dev This function swaps wETH to wstETH
    /// Swaps at 1:1 for simpicity
    /// TODO: Use Aave's swap router
    function _swap(
        uint256 _amount
    ) internal returns (uint256) {
        wETH.approve(address(aavePool), _amount);
        return _amount;
    }

    /// @notice Gets the price for an asset
    /// @dev For simplicity, wstETH price is hardcoded
    /// TODO: Use Oracle to fetch price
    function _getAssetPrice() internal returns (uint256) {
        return 0.93 ether;
    }
}
