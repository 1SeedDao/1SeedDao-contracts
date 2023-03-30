// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "self/types/investmentKey.sol";

struct CreateInvestmentParams {
    string name;
    string symbol;
    InvestmentKey key;
}
