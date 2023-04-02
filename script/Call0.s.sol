// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "solmate/tokens/WETH.sol";
import "solmate/test/utils/mocks/MockERC20.sol";
import "self/OneSeedDaoArena.sol";
import "self/Investment.sol";
import "forge-std/console2.sol";

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
        // Investment nft = new Investment();
        // OneSeedDaoArena(payable(0x4E801fB5D8159E71f3828023cAA43aF7a406AbAB)).setArgs(
        //     address(nft),
        //     100,
        //     0x817016163775AaF0B25DF274fB4b18edB67E1F26
        // );
        OneSeedDaoArena(payable(0x6d2E0a1eA3F817e0960571Ca5B0f32007155b6f7)).setInvestmentCollateral(0x9D5437C37565E7558CFf2fc1f28E5d8527DBB727, usdcAddr);
        // address[] memory tokens = new address[](1);
        // tokens[0] = address(0);
        // bool[] memory isSupporteds = new bool[](1);
        // isSupporteds[0] = true;
        // OneSeedDaoArena(payable(0x4E801fB5D8159E71f3828023cAA43aF7a406AbAB)).setSupporteds(tokens, isSupporteds);
        // MockERC20(usdtAddr).approve(0x4E801fB5D8159E71f3828023cAA43aF7a406AbAB, type(uint256).max);
        // OneSeedDaoArena(payable(0x4E801fB5D8159E71f3828023cAA43aF7a406AbAB)).invest(0x08DB60F0185e033DF205A003917B77C4aeE55BDC, 20e6);






        // Investment p = Investment(payable(0xD2686409e3aDB7E5dB73143ef5e65e38A259c098));
        // InvestmentKey memory key = p.investmentKey();
        // console2.log(p.tokenIds(0x7E0E0FCc7a6688eb7706275A615E17CaE582E525).length);
        // console2.log(p.tokenIdInfos(0));
        // console2.log(p.investorAmount(0x7E0E0FCc7a6688eb7706275A615E17CaE582E525));
        // console2.log(key.minFinancingAmount);
        // console2.log(key.maxFinancingAmount);
        // console2.log(key.userMinInvestAmount);
        // console2.log(key.financingWallet);
        // console2.log(key.duration);
        vm.stopBroadcast();
    }
}
