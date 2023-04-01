// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "solmate/tokens/WETH.sol";
import "solmate/test/utils/mocks/MockERC20.sol";
import "self/Investment.sol";
import "self/OneSeedDaoArena.sol";
import "solmate/utils/SafeTransferLib.sol";

contract OneSeedDaoTest is Test {
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
            symbol: "tt1",
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

    function testUSDTInvestSuccessAndMint() public {
        MockERC20 t = new MockERC20("TEST", "T", 18);
        t.mint(address(arena), 10000 * 1e18);
        arena.setInvestmentCollateral(address(usdtInvestment), address(t));
        arena.setInvestmentCollateral(address(ethInvestment), address(t));
        

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
        startHoax(sender);
        console2.log(usdtInvestment.tokenIds(sender)[0]);
        usdtInvestment.claimBatch(usdtInvestment.tokenIds(sender));
        vm.stopPrank();
        assertEq(t.balanceOf(sender), 11.11 * 1e18);

        ethInvestment.submitResult(30);
        ethInvestment.submitResult(30);
        ethInvestment.submitResult(30);
        ethInvestment.submitResult(30);
        console2.log("balance: %s", arena.totalSupply());
        arena.investmentDistribute(address(ethInvestment), 1000 * 1e18);
        // assertEq(usdtInvestment.pengdingClaim(0), 10 * 1e18);

        startHoax(sender);
        console2.log(ethInvestment.tokenIds(sender).length);
        ethInvestment.claimBatch(ethInvestment.tokenIds(sender));
        assertEq(t.balanceOf(sender), 10 * 1e18 + 11.11 * 1e18);
        vm.stopPrank();
    }

    function testETHInvestSuccessAndMintAndClaim() public {
        MockERC20 t = new MockERC20("TEST", "T", 18);
        t.mint(address(arena), 10000 * 1e18);
        arena.setInvestmentCollateral(address(ethInvestment), address(t));

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

        vm.stopPrank();
        arena.investmentDistribute(address(ethInvestment), 1000 * 1e18);
        // assertEq(usdtInvestment.pengdingClaim(0), 10 * 1e18);
        startHoax(sender);
        uint256[] memory ids = new uint256[](1);
        ids[0] = arena.tokenOfOwnerByIndex(sender, 0);
        ethInvestment.claimBatch(ids);
        assertEq(t.balanceOf(sender), 10 * 1e18);
        vm.stopPrank();
    }

    function randomSelectSender(uint8 random) public returns (address sender) {
        sender = allUsers[random % allUsers.length];
        startHoax(sender);
        usdt.mint(sender, MINT_AMOUNT);
    }
}
