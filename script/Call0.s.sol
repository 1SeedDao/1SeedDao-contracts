// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "solmate/tokens/WETH.sol";
import "solmate/test/utils/mocks/MockERC20.sol";
import "self/OneSeedDaoArena.sol";
import "self/Investment.sol";
import "forge-std/console2.sol";
import "self/Profile.sol";

contract ManagerCaller is Script {
    address usdtAddr = 0x310351A43c35CB2cF1dCAd649889184d123b942c;
    address usdcAddr = 0x0c0b7A497405a599022e473F8c7BF73A5E442A1e;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        // MockERC20(usdtAddr).mint(0x817016163775AaF0B25DF274fB4b18edB67E1F26, 100000000e6);
        // MockERC20(usdcAddr).mint(0x817016163775AaF0B25DF274fB4b18edB67E1F26, 100000000e6);
        MockERC20(usdtAddr).mint(0x9bA7B42139dddB676E936632f1DfE8dE8F9c0A5b, 100000000e6);
        MockERC20(usdcAddr).mint(0x9bA7B42139dddB676E936632f1DfE8dE8F9c0A5b, 100000000e6);
        // Investment nft = new Investment();
        // OneSeedDaoArena(payable(0x77C137A0BA78bB54fe94f3087CBA567736eDCCBd)).setArgs(address(nft), 100, 0x817016163775AaF0B25DF274fB4b18edB67E1F26);

        // OneSeedDaoArena(payable(0x87E9C188DA59E5564Da4CF67cA1AD48DB71Ab262)).setInvestmentCollateral(
        //     0x98a64b7106A05Ab39a8a754977cDdadb9d47504D, usdcAddr
        // );
        // OneSeedDaoArena(payable(0x87E9C188DA59E5564Da4CF67cA1AD48DB71Ab262)).investmentDistribute(
        //     0x98a64b7106A05Ab39a8a754977cDdadb9d47504D, 100e18
        // );
        // MockERC20(usdcAddr).transfer(0x87E9C188DA59E5564Da4CF67cA1AD48DB71Ab262, 100e18);

        // string memory token = OneSeedDaoArena(payable(0x87E9C188DA59E5564Da4CF67cA1AD48DB71Ab262)).tokenURI(4);
        // console2.log(token);
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

        // Profile p = Profile(0x2b4436F8FDb7ec8d3E4270680A995eaCB58B8e56);
        // address[] memory tos = new address[](1);
        // tos[0] = 0xD8435B576d5f0AC080f475d7CF8d9f959daf8069;
        // p.mintBatch(tos);
        vm.stopBroadcast();
    }
}
