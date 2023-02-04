// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./CreateInvestmentParams.sol";

struct DeploymentParams {
    address arenaAddr;
    CreateInvestmentParams cip;
}
