// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@oc/proxy/Clones.sol";
import "@oc/token/ERC20/IERC20.sol";
import "@oc/utils/cryptography/SignatureChecker.sol";
import "@oc/access/AccessControl.sol";
import "@oc/security/Pausable.sol";
import "./params/DeploymentParams.sol";
import "./params/CreateInvestmentParams.sol";
import "./error/Error.sol";
import "./interfaces/IInvestInit.sol";
import "./interfaces/IInvestCollateral.sol";

contract OneSeedDaoArena is Pausable, AccessControl {
    event CreateInvestmentInstance(address investmentAddrs, string name);

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    mapping(bytes32 => bool) private signatureUsed;
    mapping(address => bool) public isTokenSupported;
    mapping(bytes32 => address) public investmentAddrs;
    address public investmentImplAddr;
    uint256 public feePercent;
    address public validator;

    constructor(address _investmentImplAddr, uint256 _feePercent, address _validator) {
        investmentImplAddr = _investmentImplAddr;
        feePercent = _feePercent;
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
        // collaterl address error
        if (params.key.collateralToken == address(0) || params.key.financingWallet == address(0)) {
            revert Errors.ZeroAddress();
        }

        // not supported
        if (!isTokenSupported[params.key.collateralToken]) {
            revert Errors.NotSupported();
        }

        if (params.key.minFinancingAmount == 0 || params.key.maxFinancingAmount == 0 || params.key.userMinInvestAmount == 0) {
            revert Errors.ZeroAmount();
        }

        if (params.key.endTs <= block.timestamp) {
            revert Errors.SettleAgain();
        }

        bytes32 hash = ECDSA.toEthSignedMessageHash(hashMessage(params));
        require(!signatureUsed[hash], "hash used");
        require(SignatureChecker.isValidSignatureNow(validator, hash, signature), "invalid signature");
        signatureUsed[hash] = true;
        investKeyB32 = keccak256(abi.encodePacked(params.name, params.symbol, params.baseTokenURI));
        if (investmentAddrs[investKeyB32] != address(0)) {
            revert Errors.InvestmentExists(params.name);
        }
        DeploymentParams memory _deploymentParameters = DeploymentParams({arenaAddr: address(this), cip: params, feePercent: feePercent});
        investmentAddr = Clones.cloneDeterministic(investmentImplAddr, investKeyB32);
        IInvestInit(investmentAddr).initState(_deploymentParameters);

        investmentAddrs[investKeyB32] = investmentAddr;
        emit CreateInvestmentInstance(investmentAddr, params.name);
    }

    function setInvestmentCollateral(address _investmentAddr, address _claimTokenAddr) public onlyRole(DEFAULT_ADMIN_ROLE) {
        IInvestCollateral(_investmentAddr).setClaimToken(_claimTokenAddr);
        IERC20(_claimTokenAddr).approve(_investmentAddr, type(uint256).max);
    }

    function investmentDistribute(address _investmentAddr, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        IInvestCollateral(_investmentAddr).collateralDistribute(amount);
    }

    function withdrawFee(address tokenAddr, address to, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(tokenAddr).transferFrom(address(this), to, amount);
    }

    function InvestmentAddr(string memory name, string memory symbol, string memory baseTokenURI) public view returns (address) {
        return investmentAddrs[keccak256(abi.encodePacked(name, symbol, baseTokenURI))];
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function resetArgs(address _investmentImplAddr, uint256 _feePercent, address _validator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        investmentImplAddr = _investmentImplAddr;
        feePercent = _feePercent;
        validator = _validator;
    }
}
