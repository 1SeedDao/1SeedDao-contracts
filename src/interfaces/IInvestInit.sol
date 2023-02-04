// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "self/params/DeploymentParams.sol";

interface IInvestInit {
    function initState(DeploymentParams memory params) external;
}
