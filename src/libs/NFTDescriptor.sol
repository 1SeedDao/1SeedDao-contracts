// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;
pragma abicoder v2;

import "@oc/utils/Strings.sol";
import "self/interfaces/INFTDescriptor.sol";
import "self/interfaces/INFTSVG.sol";
import {IInvestState} from "self/interfaces/IInvestState.sol";
import "@oc/token/ERC20/extensions/IERC20Metadata.sol";
import "./HexStrings.sol";
import "@oc/utils/Base64.sol";

contract NFTDescriptor is INFTDescriptor {
    using Strings for uint256;

    address public nftSVGAddr;

    constructor(address _nftSVGAddr) {
        nftSVGAddr = _nftSVGAddr;
    }

    function constructTokenURI(ConstructTokenURIParams memory params) public view override returns (string memory) {
        string memory investment = IInvestState(params.investmentAddress).investmentSymbol();
        uint256 totalInvestAmount = IInvestState(params.investmentAddress).totalInvestment();
        address claimTokenAddress = IInvestState(params.investmentAddress).claimToken();
        address collateralTokenAddress = IInvestState(params.investmentAddress).investmentKey().collateralToken;
        string memory name = generateName(params.tokenId.toString());
        string memory mySharesStr = formatBalance(params.myShares, collateralTokenAddress);
        string memory totalInvestAmountStr = formatBalance(totalInvestAmount, collateralTokenAddress);

        string memory descriptionPartOne = generateDescriptionPartOne(mySharesStr, totalInvestAmountStr, addressToString(params.investmentAddress));
        string memory descriptionPartTwo = generateDescriptionPartTwo(
            params.tokenId.toString(), mySharesStr, addressToString(collateralTokenAddress), addressToString(params.investmentAddress)
        );
        INFTSVG.SVGParams memory svgParams = INFTSVG.SVGParams({
            tokenId: params.tokenId.toString(),
            totalInvestAmountStr: totalInvestAmountStr,
            mySharesStr: mySharesStr,
            investment: investment,
            investmentAddress: params.investmentAddress,
            color1: tokenToColorHex(claimTokenAddress, 0),
            color2: tokenToColorHexWithFF(params.investmentAddress, 136),
            color3: tokenToColorHexWithFF(collateralTokenAddress, 136)
        });
        string memory image = Base64.encode(bytes(INFTSVG(nftSVGAddr).generateNFT(svgParams)));
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            name,
                            '", "description":"',
                            descriptionPartOne,
                            descriptionPartTwo,
                            '", "image": "',
                            "data:image/svg+xml;base64,",
                            image,
                            '"}'
                        )
                    )
                )
            )
        );
    }

    function generateDescriptionPartOne(string memory mySharesStr, string memory totalInvestAmountStr, string memory investmentAddress)
        private
        pure
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                "This NFT represents a invest share in a 1SeedDao ",
                mySharesStr,
                "/",
                totalInvestAmountStr,
                " pool. ",
                "The owner of this NFT can claim the investment.\\n",
                "\\nInvestment Address: ",
                investmentAddress
            )
        );
    }

    function generateDescriptionPartTwo(
        string memory tokenId,
        string memory myShares,
        string memory collateralTokenAddress,
        string memory investmentAddress
    ) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                " Address: ",
                investmentAddress,
                "\\n",
                " Collateral Address: ",
                collateralTokenAddress,
                "\\nToken ID: ",
                tokenId,
                "\\nShare: ",
                myShares,
                "\\n\\n"
            )
        );
    }

    function generateName(string memory tokenId) private pure returns (string memory) {
        return string(abi.encodePacked("1SeedDao #", tokenId));
    }

    function addressToString(address addr) internal pure returns (string memory) {
        return HexStrings.toHexString((uint256(uint160(addr))), 20);
    }

    function formatBalance(uint256 balance, address token) public view returns (string memory) {
        uint256 decimal = 1 ether;
        string memory symbol = "ETH";
        if (token != address(0)) {
            (string memory tokenSymbol, uint8 tokenDecimal) = getTokenMetadata(token);
            decimal = 10 ** tokenDecimal;
            symbol = tokenSymbol;
        }
        uint256 fractionalPart = (balance % decimal) / (decimal / 100);
        uint256 integerPart = balance / decimal;
        string memory result = string(abi.encodePacked(integerPart.toString(), ".", fractionalPart.toString(), " ", symbol));
        return result;
    }

    function getTokenMetadata(address token) internal view returns (string memory, uint8) {
        return (IERC20Metadata(token).symbol(), IERC20Metadata(token).decimals());
    }

    function tokenToColorHex(address token, uint256 offset) public pure returns (string memory str) {
        return string(HexStrings.toHexStringNoPrefix((uint256(uint160(token)) >> offset), 3));
    }

    function tokenToColorHexWithFF(address token, uint256 offset) public pure returns (string memory str) {
        return string(abi.encodePacked("ff", HexStrings.toHexStringNoPrefix((uint256(uint160(token)) >> offset), 2)));
    }
}
