// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@oc/proxy/Clones.sol";
import "@oc/access/Ownable.sol";
import "./params/DeploymentParams.sol";
import "./error/Error.sol";
import "./interfaces/IInvestInit.sol";

contract OneSeedDaoArena is Ownable {
    address public investImplAddr;

    mapping(address => bool) public isTokenSupported;
    mapping(bytes32 => address) public investAddrs;
    uint256 public feePercent;

    constructor(address _investImplAddr, uint256 _feePercent) {
        investImplAddr = _investImplAddr;
        feePercent = _feePercent;
    }

    function setSupporteds(address[] memory collateralTokens, bool[] memory _isSupporteds) external onlyOwner {
        for (uint256 i = 0; i < collateralTokens.length; i++) {
            isTokenSupported[collateralTokens[i]] = _isSupporteds[i];
        }
    }

    function createInvestmentInstance(CreateInvestmentParams memory params)
        external
        onlyOwner
        returns (address investAddr, bytes32 investKeyB32)
    {
        // collaterl address error
        if (params.key.collateralToken == address(0) || params.key.financingWallet == address(0)) {
            revert Errors.ZeroAddress();
        }

        // not supported
        if (!isTokenSupported[params.key.collateralToken]) {
            revert Errors.NotSupported();
        }

        if (
            params.key.minFinancingAmount == 0 || params.key.maxFinancingAmount == 0
                || params.key.userMinInvestAmount == 0
        ) {
            revert Errors.ZeroAmount();
        }

        if (params.key.startTs >= params.key.endTs) {
            revert Errors.SettleAgain();
        }

        investKeyB32 = keccak256(
            abi.encodePacked(
                params.name,
                params.symbol,
                params.baseTokenURI,
                params.key.collateralToken,
                params.key.minFinancingAmount,
                params.key.maxFinancingAmount,
                params.key.userMinInvestAmount,
                params.key.financingWallet,
                params.key.startTs,
                params.key.endTs
            )
        );
        if (investAddrs[investKeyB32] != address(0)) {
            revert Errors.InvestmentExists(params.name);
        }
        DeploymentParams memory _deploymentParameters =
            DeploymentParams({arenaAddr: address(this), cip: params, feePercent: feePercent});
        investAddr = Clones.cloneDeterministic(investImplAddr, investKeyB32);
        IInvestInit(investAddr).initState(_deploymentParameters);

        investAddrs[investKeyB32] = investAddr;
    }
}
