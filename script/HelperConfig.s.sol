// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";

// 1. Deploy mocks when we are on a local chain
// 2. Keep track of contract addresses across different chains

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address ethrc;
        address nw;
        address br;
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
            ethrc: 0x253553366Da8546fC250F225fe3d25d0C782303b,
            nw: 0xD4416b13d2b3a9aBae7AcD5D6C2BbDBE25686401,
            br: 0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85
        });
        return mainnetConfig;
    }

    function getSepoliaConfig() public pure returns (NetworkConfig memory) {
        // get ETHRegistrarController address
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            ethrc: 0xFED6a969AaA60E4961FCD3EBF1A2e8913ac65B72,
            nw: 0x0635513f179D50A207757E05759CbD106d7dFcE8,
            br: 0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85
        });
        return sepoliaConfig;
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        // get ETHRegistrarController address

        vm.startBroadcast();
        vm.stopBroadcast();
    }
}
