// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Errors {
    error OnlyOwner();

    error InsufficientCollateral();

    error NotDeployer(address sender, address deployer);

    error ZeroAddress();

    error SubmitFailed();

    error AmountInsufficient();

    error NFTNotExists();

    error NFTAlreadyExists();

    error NFTTransferNotAllowed();

    error InvalidMerkleProof();

    error NFTNotOwner();

    error InvestmentNotExists(address addr);

    error InitTwice();

    error ParamsNotMatch();

    error NotSupported(address token);

    error NotNeedChange();

    error NotActive();

    error SettleAgain();

    error ZeroAmount();

    error Locked();

    error Insufficient();

    error ClaimFail();

    error RefundFail();

    error InvestAmountOverflow();

    error OnlyEOA();
}
