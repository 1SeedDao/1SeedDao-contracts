// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "solmate/tokens/WETH.sol";
import "solmate/test/utils/mocks/MockERC20.sol";
import "self/Investment.sol";
import "self/OneSeedDaoArena.sol";
import "solmate/utils/SafeTransferLib.sol";
import "./contracts/Multicall.sol";
import "self/Profile.sol";
import "self/libs/NFTDescriptor.sol";
import "self/libs/NFTSVG.sol";

contract ManagerDeploy is Script {
    using FixedPointMathLib for uint256;

    WETH weth9;
    MockERC20 usdt;
    MockERC20 usdc;
    OneSeedDaoArena arena;
    address[] public allUsers;
    uint256 constant MINT_AMOUNT = 20000 * 1e6;
    uint256 constant MIN_FINANCING_AMOUNT = 10000 * 1e6;

    uint256 constant ETH_MINT_AMOUNT = 20000 * 1e18;
    uint256 constant ETH_MIN_FINANCING_AMOUNT = 20000 * 1e18;

    uint256 privateKey;
    Investment usdtNFT;
    Investment ethNFT;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        deploy();
        // new Multicall0();
        vm.stopBroadcast();
    }

    function deploy() private {
        MockERC20 usdt = new MockERC20("USDT", "USDT", 6);
        MockERC20 usdc = new MockERC20("USDC", "USDC", 6);

        // (address admin, uint256 _privateKey) = makeAddrAndKey("1seed");
        // privateKey = _privateKey;
        // console2.log("admin addr:%s, private key:%s", admin, Strings.toHexString(privateKey));

        Investment nft = new Investment();
        arena = new OneSeedDaoArena(address(nft), 500, 0x817016163775AaF0B25DF274fB4b18edB67E1F26);
        address[] memory tokens = new address[](3);
        tokens[0] = address(0);
        tokens[1] = (address(usdt));
        tokens[2] = address(usdc);
        bool[] memory isSupporteds = new bool[](3);
        isSupporteds[0] = true;
        isSupporteds[1] = true;
        isSupporteds[2] = true;
        arena.setSupporteds(tokens, isSupporteds);
        // arena = OneSeedDaoArena(payable(0x87E9C188DA59E5564Da4CF67cA1AD48DB71Ab262));
        NFTDescriptor nftDescriptor = new NFTDescriptor(address(new NFTSVG()));
        arena.setTokenURIAddr(address(nftDescriptor));
    }
}
