// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface IWETH9 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}
