// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface INFTSVG {
    struct SVGParams {
        string tokenId;
        string totalInvestAmountStr;
        string mySharesStr;
        string investment;
        address investmentAddress;
        string color1;
        string color2;
        string color3;
    }

    function generateNFT(SVGParams memory params) external pure returns (string memory svg);
}
