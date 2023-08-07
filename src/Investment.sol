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
    mapping(uint256 => uint256) public claimedTokenAmounts;
    uint256 public round;

    uint256 public investTotalAmount;
    address public arenaAddr;
    address public claimTokenAddr;
    uint256 public totalClaimAmount;

    CreateInvestmentParams public cip;
    uint256 private _fee;
    uint256 public endTs;
    bool public isInvestFailed;

    event Investment(address investor, address token, uint256 amount);
    event Refund(address investor, address token, uint256 amount);
    event Claim(address investor, address token, uint256 amount, uint256 tokenId, uint256 round);
    event ChangeClaimToken(address oldAddr, address newAddr);
    event InvestStatus(bool isSuccessful, address financingWallet, uint256 remainInvestAmount, uint256 fee);

    /// @custom:oc-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the state of the Investment
     * @param params Contains owner of the contract, investment parameters (CreateInvestmentParams),
     * end time, fee and arena address.
     */
    function initState(DeploymentParams memory params) external initializer {
        __Ownable_init();
        transferOwnership(params.owner);
        cip = params.cip;
        endTs = cip.key.duration + block.timestamp;
        _fee = params.fee;
        arenaAddr = params.arenaAddr;
    }

    /**
     * @dev Submit the result of an investment
     * @param _mintBatch The number of tokens to mint
     */
    function submitResult(uint256 _mintBatch) external {
        InvestmentKey memory key = cip.key;
        if (isInvestFailed) {
            revert Errors.SubmitFailed();
        }
        uint256 normalFinancingAmount = (key.minFinancingAmount + key.maxFinancingAmount) / 2;
        if (investTotalAmount < normalFinancingAmount) {
            if (block.timestamp <= endTs) {
                revert Errors.NotNeedChange();
            }
            isInvestFailed = true;
            emit InvestStatus(false, key.financingWallet, 0, 0);
            return;
        }
        uint256 l = _infos.length() > _mintBatch ? _mintBatch : _infos.length();
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

    /**
     * @dev Internal function to handle the claim of an investment return
     * @param id Token ID for which the return should be claimed
     */
    function _claim(uint256 id) internal {
        if (claimTokenAddr == address(0)) {
            revert Errors.ZeroAddress();
        }
        if (IERC721(arenaAddr).ownerOf(id) != msg.sender) {
            revert Errors.NFTNotOwner();
        }
        uint256 canClaimAmount = pendingClaim(id);
        if (canClaimAmount == 0) {
            revert Errors.ZeroAmount();
        }
        tokenIdClaimedRounds[id] = round;
        claimedTokenAmounts[id] += canClaimAmount;
        IERC20(claimTokenAddr).transferFrom(arenaAddr, msg.sender, canClaimAmount);
        emit Claim(msg.sender, claimTokenAddr, canClaimAmount, id, round);
    }

    /**
     * @dev Claims returns on a batch of investments
     * @param ids Array of token IDs for which returns should be claimed
     */
    function claimBatch(uint256[] calldata ids) external {
        for (uint256 i; i < ids.length; i++) {
            _claim(ids[i]);
        }
    }

    /**
     * @dev Computes the amount that can be claimed for a specific token ID
     * @param id Token ID for which the pending claim amount should be computed
     * @return canClaimAmount amount that can be claimed
     */
    function pendingClaim(uint256 id) public view returns (uint256 canClaimAmount) {
        if (!tokenIdInfos.contains(id)) {
            revert Errors.NFTNotExists();
        }
        uint256 remainClaim = 0;
        for (uint256 i = tokenIdClaimedRounds[id] + 1; i <= round; i++) {
            remainClaim += collateralTokenRoundPools[i];
        }
        canClaimAmount = FixedPointMathLib.mulDivDown(remainClaim, tokenIdInfos.get(id), investTotalAmount);
    }

    /**
     * @dev Computes the amount of the return that remains to be claimed for a specific token ID
     * @param id Token ID for which the remaining claim amount should be computed
     * @return claimedAmount claimed amount
     * @return remainAmount the remaining amount to be claimed
     */
    function remainClaimNFT(uint256 id) public view override returns (uint256 claimedAmount, uint256 remainAmount) {
        if (!tokenIdInfos.contains(id)) {
            revert Errors.NFTNotExists();
        }
        claimedAmount = claimedTokenAmounts[id];
        remainAmount = FixedPointMathLib.mulDivDown(totalClaimAmount, tokenIdInfos.get(id), investTotalAmount) - claimedAmount;
    }

    /**
     * @dev Returns the claim token address and the total claim amount
     * @return The claim token address and the total claim amount
     */
    function claimToken() external view override returns (address, uint256) {
        return (claimTokenAddr, totalClaimAmount);
    }

    /**
     * @dev Returns the investment amount of a specific investor
     * @param investor Address of the investor
     * @return The amount of the investor's investment
     */

    function investorAmount(address investor) public view returns (uint256) {
        if (!_infos.contains(investor)) {
            return 0;
        }
        return _infos.get(investor);
    }

    /**
     * @dev Returns the total number of investors
     * @return The total number of investors
     */

    function investorCount() public view returns (uint256) {
        return _infos.length();
    }

    /**
     * @dev Returns the symbol of the investment
     * @return The symbol of the investment
     */

    function investmentSymbol() external view override returns (string memory) {
        return cip.symbol;
    }

    /**
     * @dev Returns the total amount of the investment
     * @return The total amount of the investment
     */

    function totalInvestment() external view override returns (uint256) {
        return investTotalAmount;
    }

    /**
     * @dev Returns an array containing all token IDs
     * @return ids An array containing all token IDs
     */

    function totalTokenIds() external view returns (uint256[] memory ids) {
        ids = new uint256[](tokenIdInfos.length());
        for (uint256 i; i < tokenIdInfos.length(); i++) {
            (uint256 id,) = tokenIdInfos.at(i);
            ids[i] = id;
        }
    }

    /**
     * @dev Returns the amount of shares associated with a specific token ID
     * @param tokenId Token ID for which the shares should be returned
     * @return The amount of shares associated with the token ID
     */

    function myShares(uint256 tokenId) external view override returns (uint256) {
        if (!tokenIdInfos.contains(tokenId)) {
            revert Errors.NFTNotExists();
        }
        return tokenIdInfos.get(tokenId);
    }

    /**
     * @dev Returns the total number of tokens
     * @return The total number of tokens
     */

    function tokenCount() external view returns (uint256) {
        return tokenIdInfos.length();
    }

    /**
     * @dev Returns the investment key
     * @return The investment key
     */

    function investmentKey() external view override returns (InvestmentKey memory) {
        return cip.key;
    }

    /**
     * @dev Returns the token IDs and the corresponding amounts for a specific owner
     * @param owner The address of the owner
     * @return ids An array containing the token IDs
     * @return amounts An array containing the corresponding amounts
     */

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

    /**
     * @dev Returns the round of a specific token ID
     * @param tokenId Token ID for which the round should be returned
     * @return The round of the token ID
     */

    function nftRound(uint256 tokenId) external view override returns (uint256) {
        return tokenIdClaimedRounds[tokenId];
    }

    /**
     * @dev Allows investors to retrieve their funds in case the investment has failed.
     * This function checks if the investment has failed and if so, transfers the invested funds back to the investor.
     * It also removes the investor's information from the investment records.
     */

    function refund() external {
        InvestmentKey memory key = cip.key;
        uint256 refundAmount = _infos.get(msg.sender);
        if (!isInvestFailed && investTotalAmount < key.minFinancingAmount) {
            if (block.timestamp > endTs) {
                isInvestFailed = true;
                emit InvestStatus(false, key.financingWallet, 0, 0);
            }
        }
        if (!isInvestFailed || refundAmount == 0) {
            revert Errors.RefundFail();
        }
        investTotalAmount -= refundAmount;
        if (key.collateralToken == address(0)) {
            SafeTransferLib.safeTransferETH(msg.sender, refundAmount);
        } else {
            IERC20(key.collateralToken).transfer(msg.sender, refundAmount);
        }
        _infos.remove(msg.sender);
        emit Refund(msg.sender, key.collateralToken, refundAmount);
    }

    /**
     * @dev Invest in the contract
     * @param investor Address of the investor
     * @param investAmount Amount to invest
     */
    function invest(address investor, uint256 investAmount) public override onlyArena {
        InvestmentKey memory key = cip.key;
        if (block.timestamp > endTs || tokenIdInfos.length() > 0) {
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

    /**
     * @dev Sets the token to be claimed and its total claimable amount.
     * This function can only be called by the arena contract.
     *
     * @param _claimTokenAddr The address of the token to be claimed.
     * @param _totalClaimAmount The total amount of tokens that can be claimed.
     */
    function setClaimToken(address _claimTokenAddr, uint256 _totalClaimAmount) public onlyArena {
        if (_claimTokenAddr == address(0)) {
            revert Errors.ZeroAddress();
        }
        emit ChangeClaimToken(claimTokenAddr, _claimTokenAddr);
        claimTokenAddr = _claimTokenAddr;
        totalClaimAmount = _totalClaimAmount;
    }

    /**
     * @dev Distributes the collateral, 1.line distrubution 2. cliff distribution
     * @param amount The amount of collateral to be distributed
     */

    function collateralDistribute(uint256 amount) public onlyArena {
        round++;
        collateralTokenRoundPools[round] = amount;
    }

    receive() external payable virtual {}
}
