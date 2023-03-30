// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "self/params/DeploymentParams.sol";
import "self/params/CreateInvestmentParams.sol";
import "self/error/Error.sol";
import "self/interfaces/IInvestInit.sol";
import "self/interfaces/IInvestCollateral.sol";
import {IInvestActions, IInvestState} from "self/interfaces/IInvestState.sol";
import "self/interfaces/IOneSeedDaoArena.sol";
import "@oc/utils/Counters.sol";
import "@oc/proxy/Clones.sol";
import "@oc/token/ERC20/IERC20.sol";
import "@oc/utils/cryptography/SignatureChecker.sol";
import "@oc/access/Ownable.sol";
import "@oc/access/AccessControl.sol";
import "@oc/security/Pausable.sol";
import "@oc/security/ReentrancyGuard.sol";
import "@oc/token/ERC721/extensions/ERC721Enumerable.sol";
import "@oc/utils/structs/EnumerableSet.sol";
import {DefaultOperatorFilterer} from "ofr/DefaultOperatorFilterer.sol";

contract OneSeedDaoArena is IOneSeedDaoArena, Pausable, AccessControl, Ownable, ERC721Enumerable, ReentrancyGuard, DefaultOperatorFilterer {
    using Strings for uint256;
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    event CreateInvestmentInstance(address investmentAddrs, string name);

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    Counters.Counter private _tokenIdCounter;
    mapping(bytes32 => bool) private signatureUsed;
    mapping(address => bool) public isTokenSupported;
    mapping(bytes32 => address) public investmentAddrs;
    EnumerableSet.AddressSet private _investmentAddrs;
    address public investmentImplAddr;
    uint256 public fee; // 1/10000
    address public validator;
    string public baseTokenURI;

    constructor(address _investmentImplAddr, uint256 _fee, address _validator) ERC721("One Seed Dao", "NFT") {
        investmentImplAddr = _investmentImplAddr;
        fee = _fee;
        validator = _validator;
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setSupporteds(address[] memory _collateralTokens, bool[] memory _isSupporteds) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i; i < _collateralTokens.length; i++) {
            isTokenSupported[_collateralTokens[i]] = _isSupporteds[i];
        }
    }

    function hashMessage(CreateInvestmentParams memory params) public view returns (bytes32) {
        return keccak256(abi.encode(block.chainid, address(this), params));
    }

    function createInvestmentInstance(CreateInvestmentParams memory params, bytes memory signature)
        public
        whenNotPaused
        returns (address investmentAddr, bytes32 investKeyB32)
    {
        // financing address error
        if (params.key.financingWallet == address(0)) {
            revert Errors.ZeroAddress();
        }

        // not supported
        if (!isTokenSupported[params.key.collateralToken]) {
            revert Errors.NotSupported();
        }

        if (params.key.minFinancingAmount == 0 || params.key.maxFinancingAmount == 0 || params.key.userMinInvestAmount == 0) {
            revert Errors.ZeroAmount();
        }

        if (params.key.duration == 0) {
            revert Errors.SettleAgain();
        }

        bytes32 hash = ECDSA.toEthSignedMessageHash(hashMessage(params));
        require(!signatureUsed[hash], "hash used");
        require(SignatureChecker.isValidSignatureNow(validator, hash, signature), "invalid signature");
        signatureUsed[hash] = true;
        investKeyB32 = keccak256(abi.encodePacked(params.name, params.symbol));
        if (investmentAddrs[investKeyB32] != address(0)) {
            revert Errors.InvestmentExists(params.name);
        }
        DeploymentParams memory _deploymentParameters = DeploymentParams({arenaAddr: address(this), cip: params, fee: fee, owner: owner()});
        investmentAddr = Clones.cloneDeterministic(investmentImplAddr, investKeyB32);
        IInvestInit(investmentAddr).initState(_deploymentParameters);

        _investmentAddrs.add(investmentAddr);
        investmentAddrs[investKeyB32] = investmentAddr;
        emit CreateInvestmentInstance(investmentAddr, params.name);
    }

    function invest(address investmentAddr, uint256 investAmount) public payable nonReentrant whenNotPaused {
        if (!_investmentAddrs.contains(investmentAddr)) {
            revert Errors.InvestmentNotExists(investmentAddr);
        }
        InvestmentKey memory key = IInvestState(investmentAddr).investmentKey();
        uint256 amount;
        if (key.collateralToken != address(0)) {
            IERC20(key.collateralToken).transferFrom(msg.sender, investmentAddr, investAmount);
            amount = investAmount;
        } else {
            payable(investmentAddr).transfer(msg.value);
            amount = msg.value;
        }
        IInvestActions(investmentAddr).invest(msg.sender, amount);
    }

    function safeMint(address investor) public override nonReentrant whenNotPaused returns (uint256 tokenId) {
        if (!_investmentAddrs.contains(msg.sender)) {
            revert Errors.InvestmentNotExists(msg.sender);
        }
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(investor, tokenId);
        _tokenIdCounter.increment();
    }

    function setInvestmentCollateral(address _investmentAddr, address _claimTokenAddr) public onlyRole(DEFAULT_ADMIN_ROLE) {
        IInvestCollateral(_investmentAddr).setClaimToken(_claimTokenAddr);
        IERC20(_claimTokenAddr).approve(_investmentAddr, type(uint256).max);
    }

    function investmentDistribute(address _investmentAddr, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        IInvestCollateral(_investmentAddr).collateralDistribute(amount);
    }

    function withdrawFee(address tokenAddr, address to, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (tokenAddr == address(0)) {
            payable(to).transfer(amount);
        } else {
            IERC20(tokenAddr).transfer(to, amount);
        }
    }

    function InvestmentAddr(string memory name, string memory symbol) public view returns (address) {
        return investmentAddrs[keccak256(abi.encodePacked(name, symbol))];
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function setArgs(address _investmentImplAddr, uint256 _fee, address _validator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        investmentImplAddr = _investmentImplAddr;
        fee = _fee;
        validator = _validator;
    }

    // ERC721
    function setBaseTokenURI(string memory _baseTokenURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseTokenURI = _baseTokenURI;
    }

    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (ownerOf(tokenId) == address(0)) {
            revert Errors.NFTNotExists();
        }
        return string(abi.encodePacked(baseTokenURI, tokenId.toString()));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721, IERC721)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    receive() external payable virtual {}
}
