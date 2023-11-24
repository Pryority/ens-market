// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {ENSMarket} from "../src/ENSMarket.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract DeployENSMarket is Script {
    function setUp() public {}

    function run() public returns (ENSMarket) {
        // Before startBroadcast -> Not a real 'tx'
        HelperConfig helperConfig = new HelperConfig();
        /** @dev If more values like other contracts are returned from the NetworkConfig, make this a tuple and target the returned values */
        (address ethrc, address nw) = helperConfig.activeNetworkConfig();
        // After startBroadcast -> Real tx
        vm.startBroadcast();
        ENSMarket market = new ENSMarket(ethrc, nw);
        vm.stopBroadcast();
        return market;
    }
}
