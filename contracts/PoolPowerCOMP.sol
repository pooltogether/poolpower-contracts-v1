// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.6.10;
pragma experimental ABIEncoderV2;

import "./PoolPower.sol";

contract PoolPowerCOMP is PoolPower {
    /**
     * @dev Initialize PoolPowerCOMP smart contract
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

    /**
     * @dev Deposit and mint shares with permit signature.
     */
    function depositWithPermit(
        uint256 amount,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(amount > 0);

        // TODO IMPLEMENT COMP SPECIFIC APPROVE BY SIGNATURE LOGIC
    }
}
