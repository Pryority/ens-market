// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {RentalSubdomainRegistrar} from "../src/RentalSubdomainRegistrar.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract DeployRentalSubdomainRegistrar is Script {
    function setUp() public {}

    function run() public returns (RentalSubdomainRegistrar) {
        // Before startBroadcast -> Not a real 'tx'
        HelperConfig helperConfig = new HelperConfig();
        /** @dev If more values like other contracts are returned from the NetworkConfig, make this a tuple and target the returned values */
        (, address nw, ) = helperConfig.activeNetworkConfig();
        // After startBroadcast -> Real tx
        vm.startBroadcast();
        RentalSubdomainRegistrar rentalSubdomainRegistrar = new RentalSubdomainRegistrar(
                nw
            );
        vm.stopBroadcast();
        return rentalSubdomainRegistrar;
    }
}
