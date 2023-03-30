// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "self/types/investmentKey.sol";

interface IInvestState {
    function investmentKey() external view returns (InvestmentKey memory);
}

interface IInvestActions {
    function invest(address investor, uint256 amount) external;
}
