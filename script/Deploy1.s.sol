// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "self/otc/Otc.sol";
import "./contracts/Multicall.sol";
import "solmate/test/utils/mocks/MockERC20.sol";

contract Manager1Deploy is Script {
    address usdtAddr = 0x23dB9cE6eBA335E2919Db22622E13492d4422827;
    address usdcAddr = 0x0Bb2d76D24c433887a01b2BDc822ee8A73C8B886;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        MockERC20 otcToken = new MockERC20("OTC", "OTC", 18);
        MockERC20 usdt = new MockERC20("USDT", "USDT", 6);
        MockERC20 usdc = new MockERC20("USDC", "USDC", 18);
        OneSeedOtc otc = new OneSeedOtc();

        otcToken.mint(0x817016163775AaF0B25DF274fB4b18edB67E1F26, 1000000e18);
        usdt.mint(0x817016163775AaF0B25DF274fB4b18edB67E1F26, 1000000e6);
        usdt.approve(address(otc), type(uint256).max);
        usdc.approve(address(otc), type(uint256).max);
        otcToken.approve(address(otc), type(uint256).max);
        usdc.mint(0x817016163775AaF0B25DF274fB4b18edB67E1F26, 1000000e6);
        address[] memory tokens = new address[](2);
        tokens[0] = address(usdt);
        tokens[1] = address(usdc);
        bool[] memory isSupporteds = new bool[](2);
        isSupporteds[0] = true;
        isSupporteds[1] = true;
        otc.setSupporteds(tokens, isSupporteds);
        otc.setOTC(address(otcToken));
        for (uint256 i = 0; i < 11; i++) {
            uint256 costPerToken = (i + 1) * 1e6;
            uint256 token = 1e18 + (i + 1) * 0.2e18;
            address u = address(usdt);
            if (i % 2 == 0) {
                u = address(usdc);
            }
            otc.createOffer(costPerToken, token, u);
        }

        new Multicall();

        vm.stopBroadcast();
    }
}
