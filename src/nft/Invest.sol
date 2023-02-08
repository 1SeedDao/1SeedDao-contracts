// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721.sol";
import "self/error/Error.sol";
import "self/interfaces/IInvestInit.sol";
import "@oc/utils/Counters.sol";
import "@oc/token/ERC20/IERC20.sol";
import "@oc/utils/structs/EnumerableMap.sol";
import "solmate/utils/FixedPointMathLib.sol";

contract InvestNFT is ERC721, IInvestInit {
    using Counters for Counters.Counter;
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    using EnumerableMap for EnumerableMap.UintToUintMap;

    Counters.Counter private _tokenIdCounter;

    EnumerableMap.AddressToUintMap private _infos;
    EnumerableMap.UintToUintMap private _nftClaim;
    uint256 public investTotalAmount;
    address public arenaAddr;
    address public claimTokenAddr;

    InvestmentKey public key;
    uint256 private _feePercent;
    bool public isInvestFailed;
    
    /// @custom:oc-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initState(DeploymentParams memory params) external initializer {
        erc721Init(params.cip.name, params.cip.symbol, params.cip.baseTokenURI);
        key = params.cip.key;
        _feePercent = params.feePercent;
        arenaAddr = params.arenaAddr;
    }

    function submitResult() external {
        if (
            block.timestamp > key.endTs
                || (block.timestamp > key.startTs && investTotalAmount >= key.maxFinancingAmount)
        ) {
            if (investTotalAmount < key.minFinancingAmount) {
                isInvestFailed = true;
            } else {
                uint256 remainInvestAmount = FixedPointMathLib.mulDivDown(investTotalAmount, 100 - _feePercent, 100);
                IERC20(key.collateralToken).transferFrom(address(this), key.financingWallet, remainInvestAmount);

                // send fee to seed's pool
                IERC20(key.collateralToken).transferFrom(
                    address(this), arenaAddr, investTotalAmount - remainInvestAmount
                );

                for (uint256 i = 0; i < _infos.length(); i++) {
                    (address investor, uint256 amount) = _infos.at(i);
                    uint256 tokenId = _tokenIdCounter.current();
                    _mint(investor, tokenId);
                    _tokenIdCounter.increment();
                    _infos.remove(investor);
                    _nftClaim.set(tokenId, amount);
                }
            }
        } else {
            revert Errors.NotNeedChange();
        }
    }

    function claim(uint256[] memory ids) external {
    }

    function refundNFT() external callerIsUser {
        if (!isInvestFailed) {
            revert Errors.RefundFail();
        }
        IERC20(key.collateralToken).transferFrom(address(this), msg.sender, _infos.get(msg.sender));
    }

    function invest(uint256 investAmount) external callerIsUser {
        if (block.timestamp < key.startTs || block.timestamp > key.endTs) {
            revert Errors.NotActive();
        }
        if (investAmount < key.userMinInvestAmount) {
            revert Errors.Insufficient();
        }
        IERC20(key.collateralToken).transferFrom(msg.sender, address(this), investAmount);
        investTotalAmount += investAmount;
        if (investTotalAmount > key.maxFinancingAmount) {
            revert Errors.InvestAmountOverflow();
        }

        _infos.set(msg.sender, _infos.get(msg.sender) + investAmount);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (ownerOf(tokenId) == address(0)) {
            revert Errors.NFTNotExists();
        }
        return string(abi.encodePacked(baseTokenURI, name));
    }

    // function setClaimToken(address _claimTokenAddr) public onlyOwner {
    //     claimTokenAddr = _claimTokenAddr;
    // }
}
