// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721.sol";
import "self/error/Error.sol";
import "self/interfaces/IInvestInit.sol";
import "@oc/utils/Strings.sol";
import "@oc/utils/Counters.sol";
import "@oc/token/ERC20/IERC20.sol";

contract InvestNFT is ERC721, IInvestInit {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => uint256) public infos;
    uint256 public investTotalAmount;

    InvestmentKey public key;
    bool public isInvestFailed;

    /// @custom:oc-upgrades-unsafe-allow constructor

    constructor() {
        _disableInitializers();
    }

    function initState(DeploymentParams memory params) external initializer {
        erc721Init(params.cip.name, params.cip.symbol, params.cip.baseTokenURI);
        key = params.cip.key;
    }

    function submitResult() external {
        if (block.timestamp > key.endTs) {
            if (investTotalAmount < key.minFinancingAmount) {
                isInvestFailed = true;
            } else {
                IERC20(key.collateralToken).transferFrom(address(this), key.financingWallet, investTotalAmount);
            }
        } else {
            revert Errors.NotNeedChange();
        }
    }

    function refundNFT(uint256[] memory tokenIds) external {
        if (!isInvestFailed) {
            revert Errors.RefundFail();
        }
        uint256 refund = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _burn(tokenIds[i]);
            refund += infos[tokenIds[i]];
        }
        IERC20(key.collateralToken).transferFrom(address(this), msg.sender, refund);
    }

    function invest(uint256 investAmount) external {
        if (block.timestamp < key.startTs || block.timestamp > key.endTs) {
            revert Errors.NotActive();
        }
        if (investAmount < key.userMinInvestAmount) {
            revert Errors.Insufficient();
        }
        IERC20(key.collateralToken).transferFrom(msg.sender, address(this), investAmount);
        if (investTotalAmount > key.maxFinancingAmount) {
            revert Errors.InvestAmountOverflow();
        }
        uint256 tokenId = _tokenIdCounter.current();
        _mint(msg.sender, tokenId);
        infos[tokenId] = investAmount;
        _tokenIdCounter.increment();
        investTotalAmount += investAmount;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (ownerOf(tokenId) == address(0)) {
            revert Errors.NFTNotExists();
        }
        return string(abi.encodePacked(baseTokenURI, tokenId.toString(), ".json"));
    }
}
