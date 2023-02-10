// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IInvestCollateral {
    function collateralDistribute(uint256 amount) external;
    function setClaimToken(address _claimTokenAddr) external;
}
