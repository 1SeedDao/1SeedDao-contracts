// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "self/types/investmentKey.sol";

struct CreateInvestmentParams {
    string name;
    string symbol;
    string baseTokenURI;
    InvestmentKey key;
}
