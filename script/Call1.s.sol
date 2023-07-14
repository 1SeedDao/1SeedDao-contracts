// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {OneSeedOtc} from "self/otc/Otc.sol";
import "forge-std/console2.sol";
import "solmate/test/utils/mocks/MockERC20.sol";

contract Manager1Caller is Script {
    MockERC20 usdt = MockERC20(0x23dB9cE6eBA335E2919Db22622E13492d4422827);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        // OneSeedOtc otc = OneSeedOtc(0xF821764BA3476C35E49eFa3BB60031CD31dBb84E);
        // usdt.approve(address(otc), type(uint256).max);
        // uint256 costPerToken = 1e5;
        // uint256 tokens = 1e18 + 0.0001e18;
        // otc.acceptOffer(0);
        // console2.log(MockERC20(0xF821764BA3476C35E49eFa3BB60031CD31dBb84E).symbol());
        // OneSeedOtc.TradeOffer[] memory  offers = otc.getOffers(0, 100);
        // console.log("offers length: %d", offers.length);
        // address[] memory tokens = otc.getSupports();
        // console2.log(tokens[0]);
        // console2.log(tokens[1]);
        // otc.expireOffers(block.timestamp + 0.5 days);
        // MockERC20(0xe6B5CDcbFE5AFA315AFd5564E53367aE99E06a71).mint(0xE426C9c4246a0FBaea7AC16a037cF6624934b0C4, 10000e18);
        OneSeedOtc(0xE6f2f7BEAb9310c01A17e1F81BA1c10e38B24ac3).expireOffers(block.timestamp + 100 seconds);
        vm.stopBroadcast();
    }
}
