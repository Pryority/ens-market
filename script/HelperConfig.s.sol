// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";

// 1. Deploy mocks when we are on a local chain
// 2. Keep track of contract addresses across different chains

contract HelperConfig {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address ethrc;
    }

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetConfig();
        } else {
            activeNetworkConfig = getAnvilConfig();
        }
    }

    function getMainnetConfig() public pure returns (NetworkConfig memory) {
        // get ETHRegistrarController address
        NetworkConfig memory mainnetConfig = NetworkConfig({
            ethrc: 0x253553366Da8546fC250F225fe3d25d0C782303b
        });
        return mainnetConfig;
    }

    function getSepoliaConfig() public pure returns (NetworkConfig memory) {
        // get ETHRegistrarController address
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            ethrc: 0xFED6a969AaA60E4961FCD3EBF1A2e8913ac65B72
        });
        return sepoliaConfig;
    }

    function getAnvilConfig() public pure returns (NetworkConfig memory) {
        // get ETHRegistrarController address
    }
}
