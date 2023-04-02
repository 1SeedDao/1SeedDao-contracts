// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Errors {
    error OnlyOwner();
    
    error InsufficientCollateral();

    error ZeroAddress();

    error AmountInsufficient();

    error NFTNotExists();

    error NFTNotOwner();

    error InvestmentExists(string name);

    error InvestmentNotExists(address addr);

    error InitTwice();

    error ParamsNotMatch();

    error NotSupported();
    error NotNeedChange();

    error NotActive();

    error SettleAgain();

    error ZeroAmount();

    error Locked();

    error InitInternalAgain();

    error Insufficient();
    error ClaimFail();
    error RefundFail();
    error InvestAmountOverflow();
}
