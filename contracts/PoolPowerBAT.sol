// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.6.10;
pragma experimental ABIEncoderV2;

import "./PoolPower.sol";

contract PoolPowerBAT is PoolPower {
    /**
     * @dev Initialize PoolPowerUSDC smart contract
     */
    constructor(
        string memory _ppName,
        string memory _ppSymbol,
        address _token,
        address _ticket,
        address _pool,
        address _poolToken,
        uint256 _feePerDeposit,
        uint256 _depositProcessMinimum,
        uint256 _minimumLiquidationAmount,
        uint256 _liquidationFee
    )
        public
        PoolPower(
            _ppName,
            _ppSymbol,
            _token,
            _ticket,
            _pool,
            _poolToken,
            _feePerDeposit,
            _depositProcessMinimum,
            _minimumLiquidationAmount,
            _liquidationFee
        )
    {}
}
