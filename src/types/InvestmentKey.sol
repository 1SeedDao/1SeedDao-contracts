// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

struct InvestmentKey {
    address collateralToken;
    uint256 minFinancingAmount;
    uint256 maxFinancingAmount;
    uint256 userMinInvestAmount;
    address financingWallet;
    uint256 endTs;
}
