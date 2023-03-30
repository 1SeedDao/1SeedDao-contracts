// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "solmate/tokens/WETH.sol";
import "solmate/test/utils/mocks/MockERC20.sol";
import "self/Investment.sol";
import "self/OneSeedDaoArena.sol";
import "solmate/utils/SafeTransferLib.sol";
import "./contracts/Multicall.sol";

contract ManagerDeploy is Script {
    using FixedPointMathLib for uint256;

    WETH weth9;
    MockERC20 usdt;
    MockERC20 usdc;
    OneSeedDaoArena arena;
    address[] public allUsers;
    uint256 constant MINT_AMOUNT = 20000 * 1e6;
    uint256 constant MIN_FINANCING_AMOUNT = 10000 * 1e6;

    uint256 constant ETH_MINT_AMOUNT = 20000 * 1e18;
    uint256 constant ETH_MIN_FINANCING_AMOUNT = 20000 * 1e18;

    uint256 privateKey;
    Investment usdtNFT;
    Investment ethNFT;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        deploy();
        // new Multicall0();
        vm.stopBroadcast();
    }

    function deploy() private {
        usdc = MockERC20(0x0Bb2d76D24c433887a01b2BDc822ee8A73C8B886);
        usdt = MockERC20(0x23dB9cE6eBA335E2919Db22622E13492d4422827);
        weth9 = WETH(payable(0x287e9a38CfD2C5b6E98830d47d2f8ADB38E921F7));

        // (address admin, uint256 _privateKey) = makeAddrAndKey("1seed");
        // privateKey = _privateKey;
        // console2.log("admin addr:%s, private key:%s", admin, Strings.toHexString(privateKey));

        // Investment nft = new Investment();
        arena = new OneSeedDaoArena(address(0x200B0A98C2fa78963A22eadBbB050020a5ACc8a8), 100, 0x817016163775AaF0B25DF274fB4b18edB67E1F26);
        address[] memory tokens = new address[](4);
        tokens[0] = (address(weth9));
        tokens[1] = (address(usdt));
        tokens[2] = address(usdc);
        tokens[3] = address(0);
        bool[] memory isSupporteds = new bool[](4);
        isSupporteds[0] = true;
        isSupporteds[1] = true;
        isSupporteds[2] = true;
        isSupporteds[3] = true;
        arena.setSupporteds(tokens, isSupporteds);

        // CreateInvestmentParams memory usdtParams = CreateInvestmentParams({
        //     name: "Test",
        //     symbol: "tt",
        //     baseTokenURI: "",
        //     key: InvestmentKey({
        //         collateralToken: address(usdt),
        //         minFinancingAmount: MIN_FINANCING_AMOUNT,
        //         maxFinancingAmount: MIN_FINANCING_AMOUNT.mulDivDown(12, 10),
        //         userMinInvestAmount: MIN_FINANCING_AMOUNT.mulDivDown(1, 100),
        //         financingWallet: admin,
        //         duration: 10 days
        //     })
        // });
        // (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, ECDSA.toEthSignedMessageHash(arena.hashMessage(usdtParams)));
        // (address investAddr,) = arena.createInvestmentInstance(usdtParams, abi.encodePacked(r, s, v));
        // usdtNFT = Investment(payable(investAddr));

        // CreateInvestmentParams memory ethParams = CreateInvestmentParams({
        //     name: "Test1",
        //     symbol: "tt1",
        //     baseTokenURI: "",
        //     key: InvestmentKey({
        //         collateralToken: address(weth9),
        //         minFinancingAmount: ETH_MIN_FINANCING_AMOUNT,
        //         maxFinancingAmount: ETH_MIN_FINANCING_AMOUNT.mulDivDown(12, 10),
        //         userMinInvestAmount: ETH_MIN_FINANCING_AMOUNT.mulDivDown(1, 100),
        //         financingWallet: admin,
        //         duration: 10 days
        //     })
        // });
        // (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(privateKey, ECDSA.toEthSignedMessageHash(arena.hashMessage(ethParams)));
        // (address investAddr1,) = arena.createInvestmentInstance(ethParams, abi.encodePacked(r1, s1, v1));
        // console2.log("Test:%s, Test1:%s", investAddr, investAddr1);
    }
}
