// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "solmate/tokens/WETH.sol";
import "solmate/test/utils/mocks/MockERC20.sol";
import "self/Investment.sol";
import "self/OneSeedDaoArena.sol";
import "solmate/utils/SafeTransferLib.sol";
import "./contracts/Multicall.sol";
import "self/Membership.sol";
import "self/libs/NFTDescriptor.sol";
import "self/libs/NFTSVG.sol";

contract ManagerDeploy is Script {
    using FixedPointMathLib for uint256;

    OneSeedDaoArena arena;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        deploy();
        // new Multicall0();
        vm.stopBroadcast();
    }

    function deploy() private {
        address usdt = 0x94b008aA00579c1307B0EF2c499aD98a8ce58e58;
        address usdc = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;
        Investment nft = new Investment();
        arena = new OneSeedDaoArena(address(nft), 500, 0x817016163775AaF0B25DF274fB4b18edB67E1F26);
        address[] memory tokens = new address[](3);
        tokens[0] = address(0);
        tokens[1] = usdt;
        tokens[2] = usdc;
        bool[] memory isSupporteds = new bool[](3);
        isSupporteds[0] = true;
        isSupporteds[1] = true;
        isSupporteds[2] = true;
        arena.setSupporteds(tokens, isSupporteds);
        // arena = OneSeedDaoArena(payable(0x87E9C188DA59E5564Da4CF67cA1AD48DB71Ab262));
        NFTDescriptor nftDescriptor = new NFTDescriptor(address(new NFTSVG()));
        arena.setTokenURIAddr(address(nftDescriptor));

        Membership profile = new Membership();
    }
}
