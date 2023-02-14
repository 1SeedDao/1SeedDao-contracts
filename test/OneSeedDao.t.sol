// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "solmate/tokens/WETH.sol";
import "solmate/test/utils/mocks/MockERC20.sol";
import "self/nft/InvestmentNFT.sol";
import "self/OneSeedDao.sol";

contract OneSeedDaoTest is Test {
    WETH weth9;
    MockERC20 usdt;
    address investmentImplAddr;
    OneSeedDaoArena arena;
    address[] public allUsers;
    uint256 constant MINT_AMOUNT = 20000 * 1e6;
    uint256 constant MIN_FINANCING_AMOUNT = 10000 * 1e6;
    CreateInvestmentParams usdtParams;
    uint256 privateKey;

    function setUp() public {
        string memory mnemonic = "test test test test test test test test test test test junk";
        for (uint32 i; i < 256; i++) {
            (address user,) = deriveRememberKey(mnemonic, i);
            allUsers.push(user);
        }

        weth9 = new WETH();
        usdt = new MockERC20("USDT", "USDT", 6);
        investmentImplAddr = address(new InvestmentNFT());

        (address admin, uint256 _privateKey) = deriveRememberKey(mnemonic, 10000);
        privateKey = _privateKey;

        arena = new OneSeedDaoArena(investmentImplAddr, 1, admin);
        address[] memory tokens = new address[](2);
        tokens[0] = (address(weth9));
        tokens[1] = (address(usdt));
        bool[] memory isSupporteds = new bool[](2);
        isSupporteds[0] = true;
        isSupporteds[1] = true;
        arena.setSupporteds(tokens, isSupporteds);

        usdtParams = CreateInvestmentParams({
            name: "Test",
            symbol: "tt",
            baseTokenURI: "",
            key: InvestmentKey({
                collateralToken: address(usdt),
                minFinancingAmount: 10000 * 1e6,
                maxFinancingAmount: 12000 * 1e6,
                userMinInvestAmount: 100 * 1e6,
                financingWallet: address(1),
                startTs: block.timestamp,
                endTs: block.timestamp + 10
            })
        });
    }

    function testUSDTInvestFailAndRefund(uint8 random) public {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, ECDSA.toEthSignedMessageHash(arena.hashMessage(usdtParams)));
        (address investAddr,) = arena.createInvestmentInstance(usdtParams, abi.encodePacked(r, s, v));
        address sender = randomSelectSender(random);
        usdt.approve(investAddr, type(uint256).max);
        InvestmentNFT(investAddr).invest(1000 * 1e6);
        // skip the timestamp
        skip(11);
        InvestmentNFT(investAddr).submitResult(1);
        InvestmentNFT(investAddr).refund(false);
        assertEq(MINT_AMOUNT, usdt.balanceOf(sender));
    }

    function testFailUSDTInvestSuccessAndRefund(uint8 random) public {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, ECDSA.toEthSignedMessageHash(arena.hashMessage(usdtParams)));
        (address investAddr,) = arena.createInvestmentInstance(usdtParams, abi.encodePacked(r, s, v));
        randomSelectSender(random);
        usdt.approve(investAddr, type(uint256).max);

        InvestmentNFT(investAddr).invest(MIN_FINANCING_AMOUNT);
        // skip the timestamp
        skip(11);
        InvestmentNFT(investAddr).submitResult(1);
        InvestmentNFT(investAddr).refund(false);
    }

    function testUSDTInvestSuccessAndMint() public {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, ECDSA.toEthSignedMessageHash(arena.hashMessage(usdtParams)));
        (address investAddr,) = arena.createInvestmentInstance(usdtParams, abi.encodePacked(r, s, v));
        MockERC20 t = new MockERC20("TEST", "T", 18);
        t.mint(address(arena), 10000 * 1e18);
        arena.setInvestmentCollateral(investAddr, address(t));

        address sender = randomSelectSender(0);
        usdt.approve(investAddr, type(uint256).max);
        InvestmentNFT(investAddr).invest(MIN_FINANCING_AMOUNT);
        // skip the timestamp
        skip(11);
        InvestmentNFT(investAddr).submitResult(100);
        assertEq(InvestmentNFT(investAddr).balanceOf(sender), 1);
        console2.log(usdt.balanceOf(usdtParams.key.financingWallet));
        console2.log(usdt.balanceOf(address(arena)));
        vm.stopPrank();
        arena.investmentDistribute(investAddr, 1000 * 1e18);
        assertEq(InvestmentNFT(investAddr).pengdingClaim(0), 1000 * 1e18);

        startHoax(sender);
        uint256[] memory ids = new uint256[](1);
        ids[0] = 0;
        InvestmentNFT(investAddr).claimBatch(ids);
        assertEq(t.balanceOf(sender), 1000 * 1e18);
    }

    function randomSelectSender(uint8 random) public returns (address sender) {
        sender = allUsers[random % allUsers.length];
        startHoax(sender);
        usdt.mint(sender, MINT_AMOUNT);
    }
}
