// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "self/error/Error.sol";
import "self/interfaces/IInvestInit.sol";
import "self/interfaces/IInvestCollateral.sol";
import {IInvestActions, IInvestState} from "self/interfaces/IInvestState.sol";
import "self/interfaces/IOneSeedDaoArena.sol";
import "@oc/utils/Counters.sol";
import "@oc/token/ERC20/IERC20.sol";
import "@oc/token/ERC721/IERC721.sol";
import "@oc/utils/structs/EnumerableMap.sol";
import "@oc/utils/Strings.sol";
import "@ocu/access/OwnableUpgradeable.sol";
import "solmate/utils/FixedPointMathLib.sol";
import "solmate/utils/SafeTransferLib.sol";

contract Investment is OwnableUpgradeable, IInvestInit, IInvestActions, IInvestState, IInvestCollateral {
    using Counters for Counters.Counter;
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    Counters.Counter private tokenCounter;
    EnumerableMap.AddressToUintMap private _infos;
    mapping(uint256 => uint256) public tokenIdInfos;
    mapping(uint256 => uint256) public tokenIdClaimedRounds;

    mapping(uint256 => uint256) public collateralTokenRoundPools;
    uint256 public round;

    uint256 public investTotalAmount;
    address public arenaAddr;
    address public claimTokenAddr;

    InvestmentKey public key;
    uint256 private _fee; // 1/10000
    uint256 public endTs;
    bool public isInvestFailed;
    string public _baseTokenURI;

    event Investment(address investor, address token, uint256 amount);
    event Refund(address investor, address token, uint256 amount);
    event Claim(address investor, address token, uint256 amount, uint256 tokenId);
    event ChangeClaimToken(address oldAddr, address newAddr);

    /// @custom:oc-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initState(DeploymentParams memory params) external initializer {
        __Ownable_init();
        transferOwnership(params.owner);
        key = params.cip.key;
        endTs = key.duration + block.timestamp;
        _fee = params.fee;
        arenaAddr = params.arenaAddr;
    }

    function investmentKey() external view override returns (InvestmentKey memory) {
        return key;
    }

    function submitResult(uint256 _mintBatch) external {
        if (block.timestamp <= endTs && investTotalAmount < key.maxFinancingAmount) {
            revert Errors.NotNeedChange();
        }
        if (investTotalAmount < key.minFinancingAmount) {
            isInvestFailed = true;
            return;
        }
        uint256 l = _infos.length();
        if (l > _mintBatch) {
            l = _mintBatch;
        }
        for (uint256 i; i < l; i++) {
            uint256 counter = tokenCounter.current();
            if (counter >= _infos.length()) break;
            (address investor, uint256 amount) = _infos.at(counter);
            uint256 tokenId = IOneSeedDaoArena(arenaAddr).safeMint(investor);
            tokenCounter.increment();
            tokenIdInfos[tokenId] = amount;
        }
        if (_infos.length() == tokenCounter.current()) {
            uint256 remainInvestAmount = FixedPointMathLib.mulDivDown(investTotalAmount, 10000 - _fee, 10000);
            if (key.collateralToken == address(0)) {
                SafeTransferLib.safeTransferETH(key.financingWallet, remainInvestAmount);
                SafeTransferLib.safeTransferETH(arenaAddr, investTotalAmount - remainInvestAmount);
            } else {
                IERC20(key.collateralToken).transfer(key.financingWallet, remainInvestAmount);
                // send fee to 1seed's pool
                IERC20(key.collateralToken).transfer(arenaAddr, investTotalAmount - remainInvestAmount);
            }
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
        tokenIdClaimedRounds[id] = round;
        IERC20(claimTokenAddr).transferFrom(arenaAddr, msg.sender, canClaimAmount);
        emit Claim(msg.sender, claimTokenAddr, canClaimAmount, id);
    }

    function claimBatch(uint256[] calldata ids) external {
        for (uint256 i; i < ids.length; i++) {
            _claim(ids[i]);
        }
    }

    function pengdingClaim(uint256 id) public view returns (uint256 canClaimAmount) {
        uint256 remainClaim = 0;
        for (uint256 i = tokenIdClaimedRounds[id]; i < round; i++) {
            remainClaim += collateralTokenRoundPools[i];
        }
        canClaimAmount = FixedPointMathLib.mulDivDown(remainClaim, tokenIdInfos[id], investTotalAmount);
    }

    function investorAmount(address investor) public view returns (uint256) {
        return _infos.get(investor);
    }

    function investorCount() public view returns (uint256) {
        return _infos.length();
    }

    function refund() external {
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
        collateralTokenRoundPools[round] = amount;
        round++;
    }

    receive() external payable virtual {}
}
