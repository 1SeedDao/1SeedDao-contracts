// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "self/params/DeploymentParams.sol";
import "self/params/CreateInvestmentParams.sol";
import "self/error/Error.sol";
import "self/interfaces/IInvestInit.sol";
import "self/interfaces/IInvestCollateral.sol";
import {IInvestActions, IInvestState} from "self/interfaces/IInvestState.sol";
import "self/interfaces/IOneSeedDaoArena.sol";
import "self/interfaces/INFTDescriptor.sol";
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
    mapping(uint256 => address) public tokenIdInvestmentAddrs;
    EnumerableSet.AddressSet private _investmentSet;
    address public investmentImplAddr;
    uint256 public fee; // 1/10000
    address public validator;
    address public tokenURIAddr;

    /**
     * @dev Constructor function initializes contract with initial investment parameters.
     * @param _investmentImplAddr Address of the investment implementation.
     * @param _fee Fee associated with the investment.
     * @param _validator Validator address.
     */
    constructor(address _investmentImplAddr, uint256 _fee, address _validator) ERC721("1Seed Investment", "1NVEST") {
        investmentImplAddr = _investmentImplAddr;
        fee = _fee;
        validator = _validator;
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Updates the supported collateral tokens for investments.
     * @param _collateralTokens Array of addresses for collateral tokens.
     * @param _isSupporteds Array of boolean flags for the corresponding collateral tokens.
     */
    function setSupporteds(address[] memory _collateralTokens, bool[] memory _isSupporteds) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i; i < _collateralTokens.length; i++) {
            isTokenSupported[_collateralTokens[i]] = _isSupporteds[i];
        }
    }

    /**
     * @dev Returns the hash of the parameters needed to create an investment.
     * @param params Parameters required for investment.
     */
    function hashMessage(CreateInvestmentParams memory params) public view returns (bytes32) {
        return keccak256(abi.encode(block.chainid, address(this), params));
    }

    /**
     * @dev Creates a new investment instance with the provided parameters and signature.
     * @param params Parameters for the investment. It includes:
     *               - name: Name of the investment instance.
     *               - symbol: Symbol of the investment instance.
     *               - key: Additional parameters for the investment. It includes:
     *                 - collateralToken: Address of the collateral token.
     *                 - minFinancingAmount: Minimum financing amount for the investment.
     *                 - maxFinancingAmount: Maximum financing amount for the investment.
     *                 - userMinInvestAmount: Minimum investment amount allowed for a user.
     *                 - financingWallet: Address of the wallet receiving the investment.
     *                 - duration: Duration of the investment.
     * @param signature Signature of the validator.
     */
    function createInvestmentInstance(CreateInvestmentParams memory params, bytes memory signature)
        public
        whenNotPaused
        returns (address investmentAddr, bytes32 investKeyB32)
    {
        // financing address error
        if (params.key.financingWallet != msg.sender) {
            revert Errors.NotDeployer(msg.sender, params.key.financingWallet);
        }

        // not supported
        if (!isTokenSupported[params.key.collateralToken]) {
            revert Errors.NotSupported(params.key.collateralToken);
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
            revert Errors.InitTwice();
        }
        DeploymentParams memory _deploymentParameters = DeploymentParams({arenaAddr: address(this), cip: params, fee: fee, owner: owner()});
        investmentAddr = Clones.cloneDeterministic(investmentImplAddr, investKeyB32);
        IInvestInit(investmentAddr).initState(_deploymentParameters);

        _investmentSet.add(investmentAddr);
        investmentAddrs[investKeyB32] = investmentAddr;
        emit CreateInvestmentInstance(investmentAddr, params.name);
    }

    /**
     * @dev Allows users to invest in an existing investment instance.
     * @param investmentAddr Address of the investment instance.
     * @param investAmount Amount to invest.
     */
    function invest(address investmentAddr, uint256 investAmount) public payable nonReentrant whenNotPaused {
        if (!_investmentSet.contains(investmentAddr)) {
            revert Errors.InvestmentNotExists(investmentAddr);
        }
        if (tx.origin != msg.sender) {
            revert Errors.OnlyEOA();
        }
        InvestmentKey memory key = IInvestState(investmentAddr).investmentKey();
        uint256 amount;
        if (key.collateralToken != address(0)) {
            require(IERC20(key.collateralToken).transferFrom(msg.sender, investmentAddr, investAmount), "1NVEST: transfer amount exceeds balance");
            amount = investAmount;
        } else {
            payable(investmentAddr).transfer(msg.value);
            amount = msg.value;
        }
        IInvestActions(investmentAddr).invest(msg.sender, amount);
    }

    /**
     * @dev Mints a new NFT token and assigns it to the investor.
     * @param investor Address of the investor.
     */
    function safeMint(address investor) public override nonReentrant whenNotPaused returns (uint256 tokenId) {
        if (!_investmentSet.contains(msg.sender)) {
            revert Errors.InvestmentNotExists(msg.sender);
        }
        tokenId = _tokenIdCounter.current();
        _safeMint(investor, tokenId);
        tokenIdInvestmentAddrs[tokenId] = msg.sender;
        _tokenIdCounter.increment();
    }

    /**
     * @dev Sets the collateral for a specific investment instance.
     * @param _investmentAddr Address of the investment instance.
     * @param _claimTokenAddr Address of the claim token.
     * @param totalClaimAmount Total claimable amount.
     */
    function setInvestmentCollateral(address _investmentAddr, address _claimTokenAddr, uint256 totalClaimAmount)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IInvestCollateral(_investmentAddr).setClaimToken(_claimTokenAddr, totalClaimAmount);
        IERC20(_claimTokenAddr).approve(_investmentAddr, totalClaimAmount);
    }

    /**
     * @dev Distributes the collateral for a specific investment instance.
     * @param _investmentAddr Address of the investment instance.
     * @param amount Amount to distribute.
     */
    function investmentDistribute(address _investmentAddr, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        IInvestCollateral(_investmentAddr).collateralDistribute(amount);
    }

    /**
     * @dev Allows withdrawal of fees from the contract.
     * @param tokenAddr Address of the token to withdraw.
     * @param to Recipient address.
     * @param amount Amount to withdraw.
     */
    function withdrawFee(address tokenAddr, address to, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (tokenAddr == address(0)) {
            payable(to).transfer(amount);
        } else {
            IERC20(tokenAddr).transfer(to, amount);
        }
    }
    /**
     * @dev Returns the address of the investment instance corresponding to the given name and symbol.
     * @param name Name of the investment.
     * @param symbol Symbol of the investment.
     */
    function InvestmentAddr(string memory name, string memory symbol) public view returns (address) {
        return investmentAddrs[keccak256(abi.encodePacked(name, symbol))];
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Updates the address of the investment implementation, the fee, and the validator.
     * @param _investmentImplAddr Address of the investment implementation.
     * @param _fee Updated fee.
     * @param _validator Updated validator address.
     */
    function setArgs(address _investmentImplAddr, uint256 _fee, address _validator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        investmentImplAddr = _investmentImplAddr;
        fee = _fee;
        validator = _validator;
    }

    /**
     * @dev Updates the address used for generating token URIs for the NFTs.
     * @param _tokenURIAddr Address of the URI generator.
     */
    function setTokenURIAddr(address _tokenURIAddr) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenURIAddr = _tokenURIAddr;
    }

    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // dynamic nft uri
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (ownerOf(tokenId) == address(0)) {
            revert Errors.NFTNotExists();
        }
        address investmentAddr = tokenIdInvestmentAddrs[tokenId];
        return INFTDescriptor(tokenURIAddr).constructTokenURI(
            INFTDescriptor.ConstructTokenURIParams({
                tokenId: tokenId,
                investmentAddress: investmentAddr,
                myShares: IInvestState(investmentAddr).myShares(tokenId)
            })
        );
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override whenNotPaused {
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
