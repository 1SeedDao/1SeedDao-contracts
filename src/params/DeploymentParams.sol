// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./CreateInvestmentParams.sol";

struct DeploymentParams {
    address arenaAddr;
    CreateInvestmentParams cip;
    uint256 feePercent;
}
