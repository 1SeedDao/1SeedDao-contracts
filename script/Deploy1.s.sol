// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "self/otc/Otc.sol";
import "./contracts/Multicall.sol";
import "solmate/test/utils/mocks/MockERC20.sol";

contract Manager1Deploy is Script {
    address usdtAddr = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address usdcAddr = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        OneSeedOtc otc = new OneSeedOtc();

        address[] memory tokens = new address[](2);
        tokens[0] = usdtAddr;
        tokens[1] = usdcAddr;
        bool[] memory isSupporteds = new bool[](2);
        isSupporteds[0] = true;
        isSupporteds[1] = true;
        otc.setSupporteds(tokens, isSupporteds);

        new Multicall();

        vm.stopBroadcast();
    }
}
