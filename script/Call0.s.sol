// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "solmate/tokens/WETH.sol";
import "solmate/test/utils/mocks/MockERC20.sol";
import "self/OneSeedDaoArena.sol";

contract ManagerCaller is Script {
    address usdtAddr = 0x23dB9cE6eBA335E2919Db22622E13492d4422827;
    address usdcAddr = 0x0Bb2d76D24c433887a01b2BDc822ee8A73C8B886;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        // MockERC20(usdtAddr).mint(0xD8435B576d5f0AC080f475d7CF8d9f959daf8069, 1000000e6);
        // MockERC20(usdcAddr).mint(0xD8435B576d5f0AC080f475d7CF8d9f959daf8069, 100000000e18);
        // MockERC20(usdtAddr).mint(0xf261C5655959e78A3a6DD8d2cfF6e314FC37581a, 1000000e6);
        // MockERC20(usdcAddr).mint(0xf261C5655959e78A3a6DD8d2cfF6e314FC37581a, 100000000e18);
        // MockERC20(usdtAddr).mint(0x9129900226EF32e5835A9899c57Ba268b44049cf, 1000000e6);
        // MockERC20(usdcAddr).mint(0x9129900226EF32e5835A9899c57Ba268b44049cf, 100000000e18);
        // OneSeedDaoArena(payable(0x21c404210DdfB5f1b59DA26fBAfcA75026fE86b2)).setArgs(
        //     0x4E86aB14A00aAAbE5A48301CC95d67587D3D8215,
        //     100,
        //     0x817016163775AaF0B25DF274fB4b18edB67E1F26
        // );
        address[] memory tokens = new address[](1);
        tokens[0] = address(0);
        bool[] memory isSupporteds = new bool[](1);
        isSupporteds[0] = true;
        OneSeedDaoArena(payable(0x21c404210DdfB5f1b59DA26fBAfcA75026fE86b2)).setSupporteds(tokens, isSupporteds);
        vm.stopBroadcast();
    }
}
