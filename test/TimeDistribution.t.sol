// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "self/erc20/Seed.sol";
import "self/distribution/TimeDistribution.sol";

contract TimeDistributionTest is Test {
    Seed token;
    TimeDistribution td;
    address admin;
    uint256 supply = 1000_000_000 * 1e18;

    function setUp() public {
        admin = makeAddr("admin");
        startHoax(admin);
        token = new Seed();
        token.mint(admin, supply);
        td = new TimeDistribution(token, admin);
        token.approve(address(td), type(uint256).max);
    }

    function testClaim() public {
        address addr0 = address(1);
        address addr1 = address(2);
        address addr2 = address(3);
        address addr3 = address(4);
        td.addInfo(addr0, supply / 100, block.timestamp, block.timestamp + 2 * 365 days, true, true);
        td.addInfo(addr1, supply * 5 / 1000, block.timestamp, block.timestamp + 2 * 365 days, true, true);
        td.addInfo(addr2, supply * 2 / 1000, block.timestamp, block.timestamp + 2 * 365 days, true, true);
        td.addInfo(addr3, supply * 2 / 100, block.timestamp, block.timestamp + 2 * 365 days, true, false);
        skip(33);
        vm.stopPrank();
        startHoax(addr0);
        td.claim();
        console2.log("t0[%s] balance is [%d]", addr0, token.balanceOf(addr0));
        vm.stopPrank();
        startHoax(addr1);
        td.claim();
        console2.log("t1[%s] balance is [%d]", addr1, token.balanceOf(addr1));
        vm.stopPrank();
        startHoax(addr2);
        td.claim();
        console2.log("t2[%s] balance is [%d]", addr2, token.balanceOf(addr2));
        vm.stopPrank();
        startHoax(addr3);
        skip(365 days);
        td.claim();
        console2.log("t3[%s] balance is [%d]", addr3, token.balanceOf(addr3));
    }
}
