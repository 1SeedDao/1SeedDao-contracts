// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "solmate/tokens/WETH.sol";
import "solmate/test/utils/mocks/MockERC20.sol";
import "self/Investment.sol";
import "self/OneSeedDaoArena.sol";
import "solmate/utils/SafeTransferLib.sol";
import "forge-std/console2.sol";
import "self/otc/Otc.sol";

contract OTCTest is Test {
    using FixedPointMathLib for uint256;
    using Strings for uint256;

    address[] public users;
    address internal currentActor;

    MockERC20 otcToken;
    MockERC20 usdt;
    OneSeedOtc otc;

    function setUp() public {
        otcToken = new MockERC20("OTC", "OTC", 18);
        usdt = new MockERC20("USDT", "USDT", 6);
        otc = new OneSeedOtc();
        address[] memory tokens = new address[](1);
        tokens[0] = (address(usdt));
        bool[] memory isSupporteds = new bool[](1);
        isSupporteds[0] = true;
        otc.setSupporteds(tokens, isSupporteds);
        otc.setOTC(address(otcToken));
        for (uint256 i = 1; i < 31; i++) {
            users.push(vm.addr(i));
        }
        for (uint256 i; i < users.length; i++) {
            deal(address(usdt), users[i], 10000e6);
            deal(address(otcToken), users[i], 10000e18);
            vm.startPrank(users[i]);
            usdt.approve(address(otc), type(uint256).max);
            otcToken.approve(address(otc), type(uint256).max);
            vm.stopPrank();
        }
        otc.expireOffers(block.timestamp + 1 days);
    }

    function test_Otc(uint8 actorIndexSeed) public {
        address seller = randomSelectSender(actorIndexSeed);
        uint256 costPerToken = 1e5;
        uint256 tokens = 1e18 + 0.0001e18;
        otc.createOffer(costPerToken, tokens, address(usdt));
        otc.cancelOffer(0);
        otc.createOffer(costPerToken, tokens * 5, address(usdt));
        vm.stopPrank();

        randomSelectSender(uint256(actorIndexSeed)+1);
        otc.acceptOffer(1);
        vm.stopPrank();

        vm.startPrank(seller, seller);
        otc.fulfilOffer(0);
        otc.createOffer(costPerToken, tokens * 5, address(usdt));
        vm.stopPrank();
                randomSelectSender(uint256(actorIndexSeed)+1);

        otc.acceptOffer(2);


        skip(1 days +1);
        otc.acceptOffer(2);
        vm.stopPrank();


    }


    function randomSelectSender(uint256 random) public returns (address sender) {
        console2.log(random);
        sender = users[random % users.length];
        startHoax(sender, sender);
    }
}
