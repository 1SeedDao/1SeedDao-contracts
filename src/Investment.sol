// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "self/error/Error.sol";
import "self/interfaces/IInvestInit.sol";
import "self/interfaces/IInvestCollateral.sol";
import {IInvestActions, IInvestState} from "self/interfaces/IInvestState.sol";
import "self/interfaces/IOneSeedDaoArena.sol";
import "@oc/token/ERC20/IERC20.sol";
import "@oc/token/ERC721/extensions/IERC721Enumerable.sol";
import "@oc/utils/structs/EnumerableMap.sol";
import "@ocu/access/OwnableUpgradeable.sol";
import "solmate/utils/FixedPointMathLib.sol";
import "solmate/utils/SafeTransferLib.sol";

contract Investment is OwnableUpgradeable, IInvestInit, IInvestActions, IInvestState, IInvestCollateral {
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    using EnumerableMap for EnumerableMap.UintToUintMap;

    EnumerableMap.AddressToUintMap private _infos;
    EnumerableMap.UintToUintMap private tokenIdInfos;
    mapping(uint256 => uint256) public tokenIdClaimedRounds;

    mapping(uint256 => uint256) public collateralTokenRoundPools;
    uint256 public round;

    uint256 public investTotalAmount;
    address public arenaAddr;
    address public claimTokenAddr;

    CreateInvestmentParams public cip;
    uint256 private _fee; // 1/10000
    uint256 public endTs;
    bool public isInvestFailed;
    string public _baseTokenURI;

    event Investment(address investor, address token, uint256 amount);
    event Refund(address investor, address token, uint256 amount);
    event Claim(address investor, address token, uint256 amount, uint256 tokenId, uint256 round);
    event ChangeClaimToken(address oldAddr, address newAddr);
    event InvestStatus(bool isSuccessful, address financingWallet, uint256 remainInvestAmount, uint256 fee);

    /// @custom:oc-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initState(DeploymentParams memory params) external initializer {
        __Ownable_init();
        transferOwnership(params.owner);
        cip = params.cip;
        endTs = cip.key.duration + block.timestamp;
        _fee = params.fee;
        arenaAddr = params.arenaAddr;
    }

    function submitResult(uint256 _mintBatch) external {
        InvestmentKey memory key = cip.key;
        if (investTotalAmount < key.minFinancingAmount) {
            if (block.timestamp <= endTs) {
                revert Errors.NotNeedChange();
            }
            isInvestFailed = true;
            emit InvestStatus(false, key.financingWallet, 0, 0);
            return;
        }
        uint256 l = _infos.length();
        if (l > _mintBatch) {
            l = _mintBatch;
        }
        for (uint256 i; i < l; i++) {
            uint256 count = tokenIdInfos.length();
            if (count >= _infos.length()) break;
            (address investor, uint256 amount) = _infos.at(count);
            uint256 tokenId = IOneSeedDaoArena(arenaAddr).safeMint(investor);
            tokenIdInfos.set(tokenId, amount);
        }
        if (_infos.length() == tokenIdInfos.length()) {
            uint256 remainInvestAmount = FixedPointMathLib.mulDivDown(investTotalAmount, 10000 - _fee, 10000);
            if (key.collateralToken == address(0)) {
                SafeTransferLib.safeTransferETH(key.financingWallet, remainInvestAmount);
                SafeTransferLib.safeTransferETH(arenaAddr, investTotalAmount - remainInvestAmount);
            } else {
                IERC20(key.collateralToken).transfer(key.financingWallet, remainInvestAmount);
                // send fee to 1seed's pool
                IERC20(key.collateralToken).transfer(arenaAddr, investTotalAmount - remainInvestAmount);
            }
            emit InvestStatus(true, key.financingWallet, remainInvestAmount, investTotalAmount - remainInvestAmount);
        }
    }

    function _claim(uint256 id) internal {
        if (claimTokenAddr == address(0)) {
            revert Errors.ZeroAddress();
        }
        if (IERC721(arenaAddr).ownerOf(id) != msg.sender) {
            revert Errors.NFTNotOwner();
        }
        uint256 canClaimAmount = pengdingClaim(id);
        if (canClaimAmount == 0) {
            revert Errors.ZeroAmount();
        }
        tokenIdClaimedRounds[id] = round;
        IERC20(claimTokenAddr).transferFrom(arenaAddr, msg.sender, canClaimAmount);
        emit Claim(msg.sender, claimTokenAddr, canClaimAmount, id, round);
    }

    function claimBatch(uint256[] calldata ids) external {
        for (uint256 i; i < ids.length; i++) {
            _claim(ids[i]);
        }
    }

    function pengdingClaim(uint256 id) public view returns (uint256 canClaimAmount) {
        if (!tokenIdInfos.contains(id)) {
            revert Errors.NFTNotExists();
        }
        uint256 remainClaim = 0;
        for (uint256 i = tokenIdClaimedRounds[id] + 1; i <= round; i++) {
            remainClaim += collateralTokenRoundPools[i];
        }
        canClaimAmount = FixedPointMathLib.mulDivDown(remainClaim, tokenIdInfos.get(id), investTotalAmount);
    }

    function claimToken() external view override returns (address) {
        return claimTokenAddr;
    }

    function investorAmount(address investor) public view returns (uint256) {
        if (!_infos.contains(investor)) {
            return 0;
        }
        return _infos.get(investor);
    }

    function investorCount() public view returns (uint256) {
        return _infos.length();
    }

    function investmentSymbol() external view override returns (string memory) {
        return cip.symbol;
    }

    function totalInvestment() external view override returns (uint256) {
        return investTotalAmount;
    }

    function totalTokenIds() external view returns (uint256[] memory ids) {
        ids = new uint256[](tokenIdInfos.length());
        for (uint256 i; i < tokenIdInfos.length(); i++) {
            (uint256 id,) = tokenIdInfos.at(i);
            ids[i] = id;
        }
    }

    function myShares(uint256 tokenId) external view override returns (uint256) {
        if (!tokenIdInfos.contains(tokenId)) {
            revert Errors.NFTNotExists();
        }
        return tokenIdInfos.get(tokenId);
    }

    function tokenCount() external view returns (uint256) {
        return tokenIdInfos.length();
    }

    function investmentKey() external view override returns (InvestmentKey memory) {
        return cip.key;
    }

    function tokenIds(address owner) external view returns (uint256[] memory ids, uint256[] memory amounts) {
        uint256 l = IERC721(arenaAddr).balanceOf(owner);
        uint256[] memory allIds = new uint256[](l);
        uint256 j;
        for (uint256 i; i < l; i++) {
            uint256 tokenId = IERC721Enumerable(arenaAddr).tokenOfOwnerByIndex(owner, i);
            if (tokenIdInfos.contains(tokenId)) {
                allIds[j] = tokenId;
                j++;
            }
        }
        ids = new uint256[](j);
        amounts = new uint256[](j);
        for (uint256 i; i < j; i++) {
            ids[i] = allIds[i];
            amounts[i] = tokenIdInfos.get(allIds[i]);
        }
    }

    function nftRound(uint256 tokenId) external view override returns (uint256) {
        return tokenIdClaimedRounds[tokenId];
    }

    function refund() external {
        InvestmentKey memory key = cip.key;
        uint256 refundAmount = _infos.get(msg.sender);
        if (!isInvestFailed || refundAmount == 0) {
            revert Errors.RefundFail();
        }

        if (key.collateralToken == address(0)) {
            SafeTransferLib.safeTransferETH(msg.sender, refundAmount);
        } else {
            IERC20(key.collateralToken).transfer(msg.sender, refundAmount);
        }
        _infos.remove(msg.sender);
        emit Refund(msg.sender, key.collateralToken, refundAmount);
    }

    function invest(address investor, uint256 investAmount) public override onlyArena {
        InvestmentKey memory key = cip.key;
        if (block.timestamp > endTs) {
            revert Errors.NotActive();
        }

        if (investAmount < key.userMinInvestAmount) {
            revert Errors.Insufficient();
        }
        investTotalAmount += investAmount;
        if (investTotalAmount > key.maxFinancingAmount) {
            revert Errors.InvestAmountOverflow();
        }

        if (_infos.contains(investor)) {
            _infos.set(investor, _infos.get(investor) + investAmount);
        } else {
            _infos.set(investor, investAmount);
        }
        emit Investment(investor, key.collateralToken, investAmount);
    }

    modifier onlyArena() {
        require(arenaAddr == msg.sender, "The caller is not a arena");
        _;
    }

    function setClaimToken(address _claimTokenAddr) public onlyArena {
        if (_claimTokenAddr == address(0)) {
            revert Errors.ZeroAddress();
        }
        emit ChangeClaimToken(claimTokenAddr, _claimTokenAddr);
        claimTokenAddr = _claimTokenAddr;
    }

    //1.line distrubution 2. cliff distribution
    //1seed must be approve the investNFT first.
    function collateralDistribute(uint256 amount) public onlyArena {
        round++;
        collateralTokenRoundPools[round] = amount;
    }

    receive() external payable virtual {}
}
