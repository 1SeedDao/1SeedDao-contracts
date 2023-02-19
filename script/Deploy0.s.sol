// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "solmate/tokens/WETH.sol";
import "solmate/test/utils/mocks/MockERC20.sol";
import "self/nft/InvestmentNFT.sol";
import "self/OneSeedDaoArena.sol";
import "solmate/utils/SafeTransferLib.sol";


contract ManagerDeploy is Script{
     using FixedPointMathLib for uint256;

    WETH weth9;
    MockERC20 usdt;
    OneSeedDaoArena arena;
    address[] public allUsers;
    uint256 constant MINT_AMOUNT = 20000 * 1e6;
    uint256 constant MIN_FINANCING_AMOUNT = 10000 * 1e6;

    uint256 constant ETH_MINT_AMOUNT = 20000 * 1e18;
    uint256 constant ETH_MIN_FINANCING_AMOUNT = 20000 * 1e18;

    uint256 privateKey;
    InvestmentNFT usdtNFT;
    InvestmentNFT ethNFT;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        deploy();
        vm.stopBroadcast();
    }

    function deploy() private{
        usdt = new MockERC20("USDT", "USDT", 6);
        weth9 = new WETH();

        (address admin, uint256 _privateKey) = makeAddrAndKey("1seed");
        privateKey = _privateKey;
        console2.log("admin addr:%s, private key:%s", admin, Strings.toHexString(privateKey));

        InvestmentNFT nft = new InvestmentNFT();
        arena = new OneSeedDaoArena(address(nft), 1, admin);
        address[] memory tokens = new address[](2);
        tokens[0] = (address(weth9));
        tokens[1] = (address(usdt));
        bool[] memory isSupporteds = new bool[](2);
        isSupporteds[0] = true;
        isSupporteds[1] = true;
        arena.setSupporteds(tokens, isSupporteds);

        CreateInvestmentParams memory usdtParams = CreateInvestmentParams({
            name: "Test",
            symbol: "tt",
            baseTokenURI: "",
            key: InvestmentKey({
                collateralToken: address(usdt),
                minFinancingAmount: MIN_FINANCING_AMOUNT,
                maxFinancingAmount: MIN_FINANCING_AMOUNT.mulDivDown(12, 10),
                userMinInvestAmount: MIN_FINANCING_AMOUNT.mulDivDown(1, 100),
                financingWallet: admin,
                endTs: block.timestamp + 10 days
            })
        });
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, ECDSA.toEthSignedMessageHash(arena.hashMessage(usdtParams)));
        (address investAddr,) = arena.createInvestmentInstance(usdtParams, abi.encodePacked(r, s, v));
        usdtNFT = InvestmentNFT(payable(investAddr));

        CreateInvestmentParams memory ethParams = CreateInvestmentParams({
            name: "Test1",
            symbol: "tt1",
            baseTokenURI: "",
            key: InvestmentKey({
                collateralToken: address(weth9),
                minFinancingAmount: ETH_MIN_FINANCING_AMOUNT,
                maxFinancingAmount: ETH_MIN_FINANCING_AMOUNT.mulDivDown(12, 10),
                userMinInvestAmount: ETH_MIN_FINANCING_AMOUNT.mulDivDown(1, 100),
                financingWallet: admin,
                endTs: block.timestamp + 10 days
            })
        });
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(privateKey, ECDSA.toEthSignedMessageHash(arena.hashMessage(ethParams)));
        (address investAddr1,) = arena.createInvestmentInstance(ethParams, abi.encodePacked(r1, s1, v1));
        console2.log("Test:%s, Test1:%s", investAddr, investAddr1);
    }
}