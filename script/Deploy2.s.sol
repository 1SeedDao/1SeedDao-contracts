// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "self/Profile.sol";

contract Manager2Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Profile profile = new Profile(payable(0x817016163775AaF0B25DF274fB4b18edB67E1F26));
        // Profile profile = new Profile(payable(0x817016163775AaF0B25DF274fB4b18edB67E1F26));
        profile.setWlMerkleRoot(0xd0fa51be6ad808441b3bda1a0b289f3d6aeff9efaf1ce290ed083749aa3cac68);
        profile.setBaseTokenURI("ipfs://bafkreifhxiuc2lgjkbk2pki5wzt4puqfebxfhydkpxmxdbdjdk2saej2pi");
        vm.stopBroadcast();
    }
}
