// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@oc/proxy/Clones.sol";
import "@oc/token/ERC20/IERC20.sol";
import "@oc/access/Ownable.sol";
import "./params/DeploymentParams.sol";
import "./error/Error.sol";
import "./interfaces/IInvestInit.sol";
import "./interfaces/IInvestCollateral.sol";

contract OneSeedDaoArena is Ownable {
    address public investmentImplAddr;

    mapping(address => bool) public isTokenSupported;
    mapping(bytes32 => address) public investmentAddrs;
    uint256 public feePercent;

    constructor(address _investmentImplAddr, uint256 _feePercent) {
        investmentImplAddr = _investmentImplAddr;
        feePercent = _feePercent;
    }

    function setSupporteds(address[] memory _collateralTokens, bool[] memory _isSupporteds) external onlyOwner {
        for (uint256 i = 0; i < _collateralTokens.length; i++) {
            isTokenSupported[_collateralTokens[i]] = _isSupporteds[i];
        }
    }

    function createInvestmentInstance(CreateInvestmentParams memory params)
        external
        onlyOwner
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

        if (
            params.key.minFinancingAmount == 0 || params.key.maxFinancingAmount == 0
                || params.key.userMinInvestAmount == 0
        ) {
            revert Errors.ZeroAmount();
        }

        if (params.key.startTs >= params.key.endTs) {
            revert Errors.SettleAgain();
        }

        investKeyB32 = keccak256(abi.encodePacked(params.name, params.symbol, params.baseTokenURI));
        if (investmentAddrs[investKeyB32] != address(0)) {
            revert Errors.InvestmentExists(params.name);
        }
        DeploymentParams memory _deploymentParameters =
            DeploymentParams({arenaAddr: address(this), cip: params, feePercent: feePercent});
        investmentAddr = Clones.cloneDeterministic(investmentImplAddr, investKeyB32);
        IInvestInit(investmentAddr).initState(_deploymentParameters);

        investmentAddrs[investKeyB32] = investmentAddr;
    }

    // function changeInvestmentOwner(address _investmentAddr, address _newOwner) public onlyOwner {
    //     Ownable(_investmentAddr).transferOwnership(_newOwner);
    // }

    function setInvestmentCollateral(address _investmentAddr, address _claimTokenAddr) public onlyOwner {
        IInvestCollateral(_investmentAddr).setClaimToken(_claimTokenAddr);
        IERC20(_claimTokenAddr).approve(_investmentAddr, type(uint256).max);
    }

    function investmentDistribute(address _investmentAddr, uint256 amount) public onlyOwner {
        IInvestCollateral(_investmentAddr).collateralDistribute(amount);
    }

    function withdrawFee(address tokenAddr, address to, uint256 amount) public onlyOwner {
        IERC20(tokenAddr).transferFrom(address(this), to, amount);
    }

    function InvestmentAddr(string memory name, string memory symbol, string memory baseTokenURI)
        public
        view
        returns (address)
    {
        return investmentAddrs[keccak256(abi.encodePacked(name, symbol, baseTokenURI))];
    }
}
