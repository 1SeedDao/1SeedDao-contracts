// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "self/types/investmentKey.sol";

interface IOneSeedDaoArena {
    function safeMint(address investor) external returns (uint256);
}
