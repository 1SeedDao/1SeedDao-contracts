// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "solmate/tokens/WETH.sol";
import "solmate/test/utils/mocks/MockERC20.sol";
import "self/Investment.sol";
import "self/OneSeedDaoArena.sol";
import "solmate/utils/SafeTransferLib.sol";
import {NFTSVG} from "self/libs/NFTSVG.sol";
import "self/libs/NFTDescriptor.sol";
import "self/Profile.sol";
import "forge-std/console2.sol";

contract OneSeedDaoTest is Test {
    using FixedPointMathLib for uint256;
    using Strings for uint256;

    WETH weth9;
    MockERC20 usdt;
    OneSeedDaoArena arena;
    address[] public allUsers;
    uint256 constant MINT_AMOUNT = 20000 * 1e6;
    uint256 constant MIN_FINANCING_AMOUNT = 10000 * 1e6;

    uint256 constant ETH_MINT_AMOUNT = 20000 * 1e18;
    uint256 constant ETH_MIN_FINANCING_AMOUNT = 20000 * 1e18;

    uint256 privateKey;
    Investment usdtInvestment;
    Investment ethInvestment;

    function setUp() public {
        string memory mnemonic = "test test test test test test test test test test test junk";
        for (uint32 i; i < 256; i++) {
            (address user,) = deriveRememberKey(mnemonic, i);
            allUsers.push(user);
        }

        weth9 = new WETH();
        usdt = new MockERC20("USDT", "USDT", 6);

        (address admin, uint256 _privateKey) = deriveRememberKey(mnemonic, 10000);
        privateKey = _privateKey;

        arena = new OneSeedDaoArena(address(new Investment()), 100, admin);
        address[] memory tokens = new address[](2);
        tokens[0] = (address(0));
        tokens[1] = (address(usdt));
        bool[] memory isSupporteds = new bool[](2);
        isSupporteds[0] = true;
        isSupporteds[1] = true;
        arena.setSupporteds(tokens, isSupporteds);

        CreateInvestmentParams memory usdtParams = CreateInvestmentParams({
            name: "Test",
            symbol: "tt",
            key: InvestmentKey({
                collateralToken: address(usdt),
                minFinancingAmount: MIN_FINANCING_AMOUNT,
                maxFinancingAmount: MIN_FINANCING_AMOUNT.mulDivDown(12, 10),
                userMinInvestAmount: MIN_FINANCING_AMOUNT.mulDivDown(1, 100),
                financingWallet: payable(address(1)),
                duration: 10
            })
        });
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, ECDSA.toEthSignedMessageHash(arena.hashMessage(usdtParams)));
        (address investAddr,) = arena.createInvestmentInstance(usdtParams, abi.encodePacked(r, s, v));
        usdtInvestment = Investment(payable(investAddr));

        CreateInvestmentParams memory ethParams = CreateInvestmentParams({
            name: "Test1",
            symbol: "UNISWAP",
            key: InvestmentKey({
                collateralToken: address(0),
                minFinancingAmount: ETH_MIN_FINANCING_AMOUNT,
                maxFinancingAmount: ETH_MIN_FINANCING_AMOUNT.mulDivDown(12, 10),
                userMinInvestAmount: ETH_MIN_FINANCING_AMOUNT.mulDivDown(1, 100),
                financingWallet: payable(address(2)),
                duration: 10
            })
        });
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(privateKey, ECDSA.toEthSignedMessageHash(arena.hashMessage(ethParams)));
        (address investAddr1,) = arena.createInvestmentInstance(ethParams, abi.encodePacked(r1, s1, v1));
        ethInvestment = Investment(payable(investAddr1));
    }

    function testUSDTInvestFailAndRefund() public {
        address sender = randomSelectSender(0);
        usdt.approve(address(arena), type(uint256).max);
        arena.invest(address(usdtInvestment), 1000 * 1e6);
        // skip the timestamp
        skip(11);
        usdtInvestment.submitResult(1);
        usdtInvestment.refund();
        assertEq(MINT_AMOUNT, usdt.balanceOf(sender));
    }

    function testFailUSDTInvestSuccessAndRefundAndClaim(uint8 random) public {
        randomSelectSender(random);
        usdt.approve(address(arena), type(uint256).max);
        arena.invest(address(usdtInvestment), MIN_FINANCING_AMOUNT);
        // skip the timestamp
        skip(11);
        usdtInvestment.submitResult(1);
        usdtInvestment.refund();
    }

    function testUSDTAndETHInvestSuccessAndMint() public {
        MockERC20 t = new MockERC20("TEST", "T", 18);
        t.mint(address(arena), 10000 * 1e18);
        arena.setInvestmentCollateral(address(usdtInvestment), address(t), 1000 * 1e18);
        arena.setInvestmentCollateral(address(ethInvestment), address(t), 1000 * 1e18);

        address sender;
        for (uint8 i; i < 100; i++) {
            address _sender = randomSelectSender(i);
            if (i == 1) sender = _sender;
            usdt.approve(address(arena), type(uint256).max);
            arena.invest(address(usdtInvestment), MIN_FINANCING_AMOUNT / 100);
            arena.invest{value: ETH_MIN_FINANCING_AMOUNT / 100}(address(ethInvestment), ETH_MIN_FINANCING_AMOUNT / 100);
            vm.stopPrank();
        }

        // skip the timestamp
        skip(11);
        usdtInvestment.submitResult(30);
        usdtInvestment.submitResult(30);
        usdtInvestment.submitResult(30);
        usdtInvestment.submitResult(30);
        // console2.log(usdt.balanceOf(usdtParams.key.financingWallet));
        // console2.log(usdt.balanceOf(address(arena)));

        arena.investmentDistribute(address(usdtInvestment), 1111 * 1e18);
        // assertEq(usdtInvestment.pengdingClaim(0), 10 * 1e18);
        startHoax(sender, sender);
        (uint256[] memory tokenIds, uint256[] memory amounts) = usdtInvestment.tokenIds(sender);
        usdtInvestment.claimBatch(tokenIds);
        vm.stopPrank();
        assertEq(t.balanceOf(sender), 11.11 * 1e18);

        ethInvestment.submitResult(30);
        ethInvestment.submitResult(30);
        ethInvestment.submitResult(30);
        ethInvestment.submitResult(30);
        arena.investmentDistribute(address(ethInvestment), 1000 * 1e18);
        // assertEq(usdtInvestment.pengdingClaim(0), 10 * 1e18);

        address addr = randomSelectSender(20);
        (uint256[] memory ethTokenIds, uint256[] memory ethAmounts) = ethInvestment.tokenIds(addr);
        arena.transferFrom(addr, sender, ethTokenIds[0]);
        vm.stopPrank();

        startHoax(sender, sender);
        (uint256[] memory ethTokenIds1, uint256[] memory ethAmounts1) = ethInvestment.tokenIds(sender);
        ethInvestment.claimBatch(ethTokenIds1);
        assertEq(t.balanceOf(sender), 10 * 1e18 + 11.11 * 1e18 + 10 * 1e18);
        vm.stopPrank();
    }

    function testETHInvestSuccessAndMintAndClaim() public {
        NFTDescriptor nftDescriptor = new NFTDescriptor(address(new NFTSVG()));
        MockERC20 t = new MockERC20("TEST", "T", 18);
        t.mint(address(arena), 10000 * 1e18);
        // arena.setInvestmentCollateral(address(ethInvestment), address(t), 1000 * 1e18);

        address sender;
        for (uint8 i; i < 100; i++) {
            address _sender = randomSelectSender(i);
            if (i == 0) sender = _sender;
            arena.invest{value: ETH_MIN_FINANCING_AMOUNT / 100}(address(ethInvestment), ETH_MIN_FINANCING_AMOUNT / 100);
            vm.stopPrank();
        }
        // skip the timestamp
        skip(11);
        ethInvestment.submitResult(30);
        ethInvestment.submitResult(30);
        ethInvestment.submitResult(30);
        ethInvestment.submitResult(30);

        arena.investmentDistribute(address(ethInvestment), 100 * 1e18);
        arena.setTokenURIAddr(address(nftDescriptor));
        // assertEq(usdtInvestment.pengdingClaim(0), 10 * 1e18);
        startHoax(sender, sender);
        uint256[] memory ids = new uint256[](1);
        ids[0] = arena.tokenOfOwnerByIndex(sender, 0);
        // ethInvestment.claimBatch(ids);
        // assertEq(t.balanceOf(sender), 1 * 1e18);
        vm.stopPrank();

        console2.log(arena.tokenURI(ids[0]));
    }

    bytes32[] public proof;

    function testProfile() public {
        startHoax(0x817016163775AaF0B25DF274fB4b18edB67E1F26, 0x817016163775AaF0B25DF274fB4b18edB67E1F26);

        Profile profile = new Profile(payable(0x817016163775AaF0B25DF274fB4b18edB67E1F26));
        // profile.publicMint{value: 0.05 ether}();
        // profile.setWlMerkleRoot(0x96b7681266b830d98fa77654d962d403814d7c37cecc50ca9d6b69fb50f43b5c);

        // proof.push(bytes32(0x4835e49da876bb29f40b9e2c1acd9f5358cc13ecf6dce009beb8721cb6c7d045));
        // proof.push(bytes32(0xbf87bcb3644e453db5a37112073cea5bfc72feb67536cb4bf1f5022fecf0ef29));
        // proof.push(bytes32(0x9e1184f3dbef40d31805f12a001b60d9936fae03558f758fba177130752af139));
        // proof.push(bytes32(0x3e2ee8cde18306f003b978b23dfea4a686e1c5a879d702cfb8ec78643c2750f3));
        // proof.push(bytes32(0x677b4038eb5c8d3d990710bf18dd1bf24589cfb8d138adefd0fb878bc6d70a51));
        // proof.push(bytes32(0x535d193a2b2637331a0a470588e39e55e0792e4233c2be143abeaf24c6521b7c));
        // proof.push(bytes32(0x77343736fd02cc9c9bc7f51799ca73a35de05fcef9a1eeb2127d88cb788649f5));
        // proof.push(bytes32(0x730e419bbca19a7d0a515cfa07379265b28622334d8c85376e381d900b10d347));
        // proof.push(bytes32(0x61ebc486f6420ff5162432ca64db3753c9ec13a968e12206e52ca8fe191124bb));
        // proof.push(bytes32(0xd15508aeb6a720236bb3a829a99ab393f684c5f653f48015b896605e2460cd3e));
        // proof.push(bytes32(0x525a441feb503831ec026572280b3236e5adce786d1a2f70acba42401ae61d13));
        // proof.push(bytes32(0x7cd251c9fb5dd455727f870254067b0c14dde05b64f1eb9e7afdbae62b27621b));
        // proof.push(bytes32(0x11b68da093d9e0c683d6c2d4b46086dc54f4e4d8a91d29c1bffa0040e0566d01));
        // proof.push(bytes32(0xb0c5c66450624e495cfc9a3c1571d56eacee45e6e9846583afe2ed4c9adc0a82));
        // proof.push(bytes32(0x3f385ea8fe515574c37f0150192ab1d25f59788d37a733f44e3aff2c009f5c1c));
        // proof.push(bytes32(0x81a6366473c68cc10ac57ac5edf1158799fb266cdef630ad11436b5e60453b23));
        // proof.push(bytes32(0x4d774336a021a8c0d5ece5201ffd1a06ef285f6eb74dc6ddd1d678f6d6c16de0));

        profile.setWlMerkleRoot(0xf092214d5e00a7a81ef50f320986113467c4df34f06dc871f5f46da3b7eea9b6);

        proof.push(bytes32(0x329ca8f9682548a6e8776829589570f7f12d85044dce28b093a891290440b7a8));
        proof.push(bytes32(0xa00d5dc8c35098d583728d04c692c9afc514606c78b681f304c09afe1c26894e));
        proof.push(bytes32(0x93b3672c17c9712d61dc8b298f817f6d4f4fd6ce9f661688f8783a4c7b6f5420));
        proof.push(bytes32(0xc121fe2fbd789926c2e2e9da490ef91ad7da3d434509a92af405298515836df3));
        proof.push(bytes32(0xc90d156188bb05134251f461ce2e1388ddabb34b51b4b38fcb2522b631638f63));
        proof.push(bytes32(0x0f21db7e364d0519cff4280e3fd128c48bbf1c33ea686ada03085c4059f47469));
        proof.push(bytes32(0x736402f2da6943ab168cacca76f5561ac63e66d1c9a41c1f9be3a5b8dbc90365));
        proof.push(bytes32(0xd5e9430d2b591f24bc62ca0a9dbd6a3d5ce8abf6d3bf2b037cb33d1dce535c99));
        proof.push(bytes32(0xb3cb409eb9c69e88e8d8095f03fe94bb56d2f0e58c4a57f9d8f956a68559f733));
        proof.push(bytes32(0x29ae46e99d24c6ca849ac86b1195e41742bcf6ed6b95576559020ec0e9cbaa22));
        proof.push(bytes32(0x6ec5ce3a912d2da4bc052378634a7136e516b896574c83f460863fd061119679));
        proof.push(bytes32(0xf37828010c1c590c05519c2740f1f53ba9fd1b3bc454954f44013eaff90c2946));
        proof.push(bytes32(0x4459f9a18df24e43424fbd878e0937adc9cde5cacaa324a9bb9dbd86d6a1449c));
        proof.push(bytes32(0x7cd06893975986d30538635c23488a88997f31f64b9fbb378299706f948a79cf));
        proof.push(bytes32(0xe0a632ee94cd5a3327cd85ab407501c4a5b8712010be69528f1e74d569835a6e));
        proof.push(bytes32(0x2b00be7ee274a29eb69d506b4e96ea798883b8fb69b780e321f4188cc2a8606d));
        proof.push(bytes32(0xbe07a8864af02682cbc965e67cd35e02ea4f179b76636709f1021df051dcbb89));
        proof.push(bytes32(0xf400c4aa0969cd2ed16fb3412fa7eef6b4cdea6f5a60056be6fc810877159180));
        proof.push(bytes32(0x446350716b4c9e2ef27fbe28b86f873e05af5ca7039c2c074e7bc8620942db81));
        proof.push(bytes32(0xbe7966f6450de89dc58281dc0bcf3918cb88471185f81be5ad244fc03f399302));
        proof.push(bytes32(0xfdbb7d14a8ea2c9905d95e6168e0db4cd0bc307a4a4d5a45e2339a57ae4554ac));
        

        profile.wlMint(proof);
         vm.stopPrank();

        address _sender = randomSelectSender(1);
        profile.publicMint{value: 0.05 ether}();

    }

    function randomSelectSender(uint8 random) public returns (address sender) {
        sender = allUsers[random % allUsers.length];
        startHoax(sender, sender);
        usdt.mint(sender, MINT_AMOUNT);
    }

    function testHexPrefix() public {
        NFTSVG svg = new NFTSVG();
        NFTDescriptor descriptor = new NFTDescriptor(address(svg));
        console2.log(address(svg));
        console2.log(descriptor.tokenToColorHexWithFF(address(svg), 0));
    }
}
