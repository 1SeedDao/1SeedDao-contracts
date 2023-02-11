// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721.sol";
import "self/error/Error.sol";
import "self/interfaces/IInvestInit.sol";
import "self/interfaces/IInvestCollateral.sol";
import "self/interfaces/IWETH9.sol";
import "@oc/utils/Counters.sol";
import "@oc/token/ERC20/IERC20.sol";
import "@oc/utils/structs/EnumerableMap.sol";
import "@oc/access/Ownable.sol";
import "solmate/utils/FixedPointMathLib.sol";

contract InvestmentNFT is ERC721, IInvestInit, IInvestCollateral, Ownable {
    using Counters for Counters.Counter;
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    using EnumerableMap for EnumerableMap.UintToUintMap;

    Counters.Counter private _tokenIdCounter;
    EnumerableMap.AddressToUintMap private _infos;
    mapping(uint256 => uint256) public tokenIdInfos;
    mapping(uint256 => uint256) public tokenIdClaimedRounds;

    mapping(uint256 => uint256) public collateralTokenRoundPools;
    uint256 public round;

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

                // send fee to 1seed's pool
                IERC20(key.collateralToken).transferFrom(
                    address(this), arenaAddr, investTotalAmount - remainInvestAmount
                );

                // maybe out of gas
                for (uint256 i = 0; i < _infos.length(); i++) {
                    (address investor, uint256 amount) = _infos.at(i);
                    uint256 tokenId = _tokenIdCounter.current();
                    _mint(investor, tokenId);
                    _tokenIdCounter.increment();
                    // _infos.remove(investor);
                    tokenIdInfos[tokenId] = amount;
                }
            }
        } else {
            revert Errors.NotNeedChange();
        }
    }

    function _claim(uint256 id) internal {
        if (claimTokenAddr == address(0)) {
            revert Errors.ZeroAddress();
        }
        uint256 remainClaim = 0;
        for (uint256 i = tokenIdClaimedRounds[id]; i < round; i++) {
            remainClaim += collateralTokenRoundPools[i];
        }
        tokenIdClaimedRounds[id] = round;
        uint256 canClaimAmount = FixedPointMathLib.mulDivDown(remainClaim, tokenIdInfos[id], investTotalAmount);
        IERC20(key.collateralToken).transferFrom(arenaAddr, msg.sender, canClaimAmount);
    }

    function claimBatch(uint256[] calldata ids) external {
        for (uint256 i = 0; i < ids.length; i++) {
            _claim(ids[i]);
        }
    }

    function refund(bool isEther) external callerIsUser {
        uint256 refundAmount = _infos.get(msg.sender);
        if (!isInvestFailed || refundAmount == 0) {
            revert Errors.RefundFail();
        }
      
        if (isEther) {
            IWETH9(key.collateralToken).withdraw(refundAmount);
           (bool sent, bytes memory data) = msg.sender.call{value: refundAmount}("");
            require(sent, "failed to send Ether");
        } else {
            IERC20(key.collateralToken).transferFrom(address(this), msg.sender, refundAmount);
        }
        _infos.remove(msg.sender);
    }

    function invest(uint256 investAmount) payable external callerIsUser {
        if (block.timestamp < key.startTs || block.timestamp > key.endTs) {
            revert Errors.NotActive();
        }
        if (investAmount < key.userMinInvestAmount) {
            revert Errors.Insufficient();
        }
        if (msg.value == investAmount) {
            (bool sent, bytes memory data) = key.collateralToken.call{value: msg.value}("");
            require(sent, "failed to send Ether");
        } else {
            IERC20(key.collateralToken).transferFrom(msg.sender, address(this), investAmount);
        }
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
        return baseTokenURI;
    }

    function setClaimToken(address _claimTokenAddr) public onlyOwner {
        if (_claimTokenAddr == address(0)) {
            revert Errors.ZeroAddress();
        }
        claimTokenAddr = _claimTokenAddr;
    }

    //@notice: 1.line distrubution 2. cliff distribution
    //1seed must be approve the investNFT first.
    function collateralDistribute(uint256 amount) public onlyOwner {
        round++;
        collateralTokenRoundPools[round] = amount;
    }
}
