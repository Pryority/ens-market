// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {IETHRegistrarController as IETHRC} from "@ensdomains/ethregistrar/IETHRegistrarController.sol";
import {IPriceOracle} from "@ensdomains/ethregistrar/IPriceOracle.sol";
import {ENSMarket} from "../src/ENSMarket.sol";
import {DeployENSMarket} from "../script/DeployENSMarket.s.sol";

contract ENSMarketTest is Test {
    ENSMarket market;
    address alice;
    uint256 mainnetFork;

    string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");

    function setUp() public {
        mainnetFork = vm.createFork(MAINNET_RPC_URL);
        vm.selectFork(mainnetFork);
        DeployENSMarket deployENSMarket = new DeployENSMarket();
        market = deployENSMarket.run();
        alice = makeAddr("alice");
    }

    function test_isAllAvailableNames() public {
        string[] memory names = new string[](2);
        names[0] = "nick";
        names[1] = "vitalik";
        assertFalse(market.isAllAvailableNames(names));
    }

    function test_isEachAvailableNames() public {
        assertEq(vm.activeFork(), mainnetFork);
        string[] memory names = new string[](2);
        names[0] = "nick";
        names[1] = "vitalik";
        bool[] memory available = market.isEachAvailableNames(names);
        for (uint256 i = 0; i < available.length; i++) {
            assertEq(false, available[i]);
        }
    }

    function test_isAvailableName() public {
        string memory name = "nick";
        assertFalse(market.isAvailableName(name));
    }

    function test_renew() public {
        assertEq(vm.activeFork(), mainnetFork);
        string memory name = "nick";
        IPriceOracle.Price memory price = market.getRentPrice(name);
        uint256 cost = price.base + price.premium;
        market.renew{value: cost}(name);
    }
}
