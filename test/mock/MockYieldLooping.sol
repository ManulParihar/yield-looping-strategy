// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {YieldLooping} from "../../src/contracts/YieldLooping.sol";

contract MockYieldLooping is YieldLooping {

    constructor(
        address _wstETH,
        address _wETH,
        address _aavePool
    ) YieldLooping(_wstETH, _wETH, _aavePool) {}

    function totalValue() external returns (uint256) {
        return _totalValue();
    }

    function getAssetPrice(address _asset) external returns (uint256) {
        return _getAssetPrice(_asset);
    }
}