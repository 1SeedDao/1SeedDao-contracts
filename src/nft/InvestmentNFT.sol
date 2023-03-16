// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "self/error/Error.sol";
import "self/interfaces/IInvestInit.sol";
import "self/interfaces/IInvestCollateral.sol";
import "self/interfaces/IWETH9.sol";
import "@oc/utils/Counters.sol";
import "@oc/token/ERC20/IERC20.sol";
import "@oc/utils/structs/EnumerableMap.sol";
import "@oc/utils/Strings.sol";
import "@oc/security/ReentrancyGuard.sol";
import "@ocu/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@ocu/access/OwnableUpgradeable.sol";
import "solmate/utils/FixedPointMathLib.sol";
import "solmate/utils/SafeTransferLib.sol";
import {DefaultOperatorFilterer} from "ofr/DefaultOperatorFilterer.sol";

contract InvestmentNFT is
    OwnableUpgradeable,
    ERC721EnumerableUpgradeable,
    ReentrancyGuard,
    DefaultOperatorFilterer,
    IInvestInit,
    IInvestCollateral
{
    using Strings for uint256;
    using Counters for Counters.Counter;
    using EnumerableMap for EnumerableMap.AddressToUintMap;

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
    uint256 private _fee; // 1/10000
    uint256 public endTs;
    bool public isInvestFailed;
    string public _baseTokenURI;

    event Investment(address investor, address token, uint256 amount);
    event Refund(address investor, address token, uint256 amount);
    event Claim(address investor, address token, uint256 amount, uint256 tokenId);

    /// @custom:oc-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initState(DeploymentParams memory params) external initializer {
        __ERC721_init(params.cip.name, params.cip.symbol);
        __ERC721Enumerable_init();
        __Ownable_init();
        transferOwnership(params.owner);
        _baseTokenURI = params.cip.baseTokenURI;
        key = params.cip.key;
        endTs = key.duration + block.timestamp;
        _fee = params.fee;
        arenaAddr = params.arenaAddr;
    }

    // careful gas
    function submitResult(uint256 _mintBatch) external nonReentrant {
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
            uint256 tokenId = _tokenIdCounter.current();
            if (tokenId >= _infos.length()) break;
            (address investor, uint256 amount) = _infos.at(tokenId);
            _safeMint(investor, tokenId);
            _tokenIdCounter.increment();
            tokenIdInfos[tokenId] = amount;
        }
        if (_infos.length() == _tokenIdCounter.current()) {
            uint256 remainInvestAmount = FixedPointMathLib.mulDivDown(investTotalAmount, 10000 - _fee, 10000);
            if (key.collateralToken == address(0)) {
                SafeTransferLib.safeTransferETH(key.financingWallet, remainInvestAmount);
                SafeTransferLib.safeTransferETH(arenaAddr,investTotalAmount - remainInvestAmount);
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
        if (ownerOf(id) != msg.sender) {
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

    function investmentAmount(address investor) public view returns (uint256) {
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
            SafeTransferLib.safeTransferETH(msg.sender,refundAmount);
        } else {
            IERC20(key.collateralToken).transfer(msg.sender, refundAmount);
        }
        _infos.remove(msg.sender);
        emit Refund(msg.sender, key.collateralToken, refundAmount);
    }

    function invest(uint256 investAmount) public payable nonReentrant {
        if (block.timestamp > endTs) {
            revert Errors.NotActive();
        }
        if (key.collateralToken != address(0)) {
            IERC20(key.collateralToken).transferFrom(msg.sender, address(this), investAmount);
        } else {
            investAmount = msg.value;
        }
        if (investAmount < key.userMinInvestAmount) {
            revert Errors.Insufficient();
        }
        investTotalAmount += investAmount;
        if (investTotalAmount > key.maxFinancingAmount) {
            revert Errors.InvestAmountOverflow();
        }

        if (_infos.contains(msg.sender)) {
            _infos.set(msg.sender, _infos.get(msg.sender) + investAmount);
        } else {
            _infos.set(msg.sender, investAmount);
        }
        emit Investment(msg.sender, key.collateralToken, investAmount);
    }

    modifier onlyArena() {
        require(arenaAddr == msg.sender, "The caller is not a arena");
        _;
    }

    function setClaimToken(address _claimTokenAddr) public onlyArena {
        if (_claimTokenAddr == address(0)) {
            revert Errors.ZeroAddress();
        }
        claimTokenAddr = _claimTokenAddr;
    }

    //1.line distrubution 2. cliff distribution
    //1seed must be approve the investNFT first.
    function collateralDistribute(uint256 amount) public onlyArena {
        collateralTokenRoundPools[round] = amount;
        round++;
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (ownerOf(tokenId) == address(0)) {
            revert Errors.NFTNotExists();
        }
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    receive() external payable virtual {
        invest(msg.value);
    }
}
