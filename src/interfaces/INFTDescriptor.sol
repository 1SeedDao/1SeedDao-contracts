// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface INFTDescriptor {
    struct ConstructTokenURIParams {
        uint256 tokenId;
        address investmentAddress;
        uint256 myShares;
    }

    function constructTokenURI(ConstructTokenURIParams memory params) external view returns (string memory);
}
