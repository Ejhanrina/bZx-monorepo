/**
 * Copyright 2017–2018, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.4.24;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/math/Math.sol";

import "../proxy/BZxProxiable.sol";
import "../shared/OrderTakingFunctions.sol";


contract BZxOrderTaking is BZxStorage, BZxProxiable, OrderTakingFunctions {
    using SafeMath for uint256;

    constructor() public {}

    function()  
        public
    {
        revert("fallback not allowed");
    }

    function initialize(
        address _target)
        public
        onlyOwner
    {
        targets[bytes4(keccak256("takeLoanOrderAsTrader(address[8],uint256[11],bytes,address,uint256,address,bool,bytes)"))] = _target;
        targets[bytes4(keccak256("takeLoanOrderAsLender(address[8],uint256[11],bytes,bytes)"))] = _target;
    }

    /// @dev Takes the order as trader
    /// @param orderAddresses Array of order's makerAddress, loanTokenAddress, interestTokenAddress, collateralTokenAddress, feeRecipientAddress, oracleAddress, takerAddress, tradeTokenToFill.
    /// @param orderValues Array of order's loanTokenAmount, interestAmount, initialMarginAmount, maintenanceMarginAmount, lenderRelayFee, traderRelayFee, maxDurationUnixTimestampSec, expirationUnixTimestampSec, makerRole (0=lender, 1=trader), withdrawOnOpen, and salt.
    /// @param oracleData An arbitrary length bytes stream to pass to the oracle.
    /// @param collateralTokenFilled Desired address of the collateralTokenAddress the trader wants to use.
    /// @param loanTokenAmountFilled Desired amount of loanToken the trader wants to borrow.
    /// @param tradeTokenToFill If non-zero address, will swap the loanToken for this asset using the oracle.
    /// @param withdrawOnOpen If true, will overcollateralize the loan and withdraw the position token to the trader's wallet. If set, tradeTokenToFill is ignored.
    /// @param signature ECDSA signature in raw bytes (rsv).
    /// @return Total amount of loanToken borrowed (uint).
    /// @dev Traders can take a portion of the total coin being lended (loanTokenAmountFilled).
    /// @dev Traders also specify the token that will fill the margin requirement if they are taking the order.
    function takeLoanOrderAsTrader(
        address[8] orderAddresses,
        uint[11] orderValues,
        bytes oracleData,
        address collateralTokenFilled,
        uint loanTokenAmountFilled,
        address tradeTokenToFill,
        bool withdrawOnOpen,
        bytes signature)
        external
        nonReentrant
        tracksGas
        returns (uint)
    {
        bytes32 loanOrderHash = _addLoanOrder(
            orderAddresses,
            orderValues,
            oracleData,
            signature);

        LoanOrder memory loanOrder = _takeLoanOrder(
            loanOrderHash,
            collateralTokenFilled,
            loanTokenAmountFilled,
            1, // takerRole
            withdrawOnOpen
        );

        if (!withdrawOnOpen && tradeTokenToFill != address(0)) {
            _fillTradeToken(
                loanOrder,
                tradeTokenToFill
            );
        }

        return loanTokenAmountFilled;
    }

    /// @dev Takes the order as lender
    /// @param orderAddresses Array of order's makerAddress, loanTokenAddress, interestTokenAddress, collateralTokenAddress, feeRecipientAddress, oracleAddress, takerAddress, tradeTokenToFill.
    /// @param orderValues Array of order's loanTokenAmount, interestAmount, initialMarginAmount, maintenanceMarginAmount, lenderRelayFee, traderRelayFee, maxDurationUnixTimestampSec, expirationUnixTimestampSec, makerRole (0=lender, 1=trader), withdrawOnOpen, and salt.
    /// @param oracleData An arbitrary length bytes stream to pass to the oracle.
    /// @param signature ECDSA signature in raw bytes (rsv).
    /// @return Total amount of loanToken borrowed (uint).
    /// @dev Lenders have to fill the entire desired amount the trader wants to borrow.
    /// @dev This makes loanTokenAmountFilled = loanOrder.loanTokenAmount.
    function takeLoanOrderAsLender(
        address[8] orderAddresses,
        uint[11] orderValues,
        bytes oracleData,
        bytes signature)
        external
        nonReentrant
        tracksGas
        returns (uint)
    {
        bytes32 loanOrderHash = _addLoanOrder(
            orderAddresses,
            orderValues,
            oracleData,
            signature);

        // lenders have to fill the entire uncanceled loanTokenAmount
        uint loanTokenAmountFilled = orderValues[0].sub(_getUnavailableLoanTokenAmount(loanOrderHash));
        LoanOrder memory loanOrder = _takeLoanOrder(
            loanOrderHash,
            orderAddresses[3], // collateralTokenFilled
            loanTokenAmountFilled,
            0, // takerRole
            orderAux[loanOrderHash].withdrawOnOpen
        );

        if (!orderAux[loanOrderHash].withdrawOnOpen && orderAux[loanOrderHash].tradeTokenToFill != address(0)) {
            _fillTradeToken(
                loanOrder,
                orderAux[loanOrderHash].tradeTokenToFill
            );
        }

        return loanTokenAmountFilled;
    }
}

