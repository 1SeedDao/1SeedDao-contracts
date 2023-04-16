// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "self/types/investmentKey.sol";

interface IInvestState {
    function investmentKey() external view returns (InvestmentKey memory);

    function investmentSymbol() external view returns (string memory);

    function totalInvestment() external view returns (uint256);

    function myShares(uint256 tokenId) external view returns (uint256);

    function nftRound(uint256 tokenId) external view returns (uint256);

    function claimToken() external view returns (address);
}

interface IInvestActions {
    function invest(address investor, uint256 amount) external;
}
