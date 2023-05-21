// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "self/otc/Otc.sol";
import "./contracts/Multicall.sol";
import "solmate/test/utils/mocks/MockERC20.sol";

contract Manager1Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        // MockERC20 otcToken = new MockERC20("OTC", "OTC", 18);
        // MockERC20 usdt = new MockERC20("USDT", "USDT", 6);
        // MockERC20 usdc = new MockERC20("USDC", "USDC", 6);
        // OneSeedOtc otc = new OneSeedOtc();

        // otcToken.mint(0x817016163775AaF0B25DF274fB4b18edB67E1F26, 1000000e18);
        // usdt.mint(0x817016163775AaF0B25DF274fB4b18edB67E1F26, 1000000e6);
        // usdt.approve(address(otc), type(uint256).max);
        // usdc.approve(address(otc), type(uint256).max);
        // otcToken.approve(address(otc), type(uint256).max);
        // usdc.mint(0x817016163775AaF0B25DF274fB4b18edB67E1F26, 1000000e6);
        // address[] memory tokens = new address[](2);
        // tokens[0] = address(usdt);
        // tokens[1] = address(usdc);
        // bool[] memory isSupporteds = new bool[](2);
        // isSupporteds[0] = true;
        // isSupporteds[1] = true;
        // otc.setSupporteds(tokens, isSupporteds);
        // otc.setOTC(address(otcToken));
        // for (uint256 i = 0; i < 11; i++) {
        //     uint256 costPerToken = (i+1)*1e5;
        //     uint256 token = 1e18 + 0.0001e18 + i*1e18;
        //     address u = address(usdt);
        //     if (i % 2 == 0) {
        //         u = address(usdc);
        //     }
        //     otc.createOffer(costPerToken, token, u);
        // }

        new Multicall();

        vm.stopBroadcast();
    }
}
