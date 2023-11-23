// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {IETHRegistrarController as IETHRC} from "@ensdomains/ethregistrar/IETHRegistrarController.sol";
import {IPriceOracle} from "@ensdomains/ethregistrar/IPriceOracle.sol";
import {ENSMarket} from "../src/ENSMarket.sol";
import {DeployENSMarket} from "../script/DeployENSMarket.s.sol";

contract ENSMarketTest is Test {
    ENSMarket market;
    // IETHRC immutable i_IETHRC = IETHRC(0x253553366Da8546fC250F225fe3d25d0C782303b);
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

    function test_available() public {
        string memory name = "nick";
        assertFalse(market.isAvailableName(name));
    }

    function test_renew() public {
        assertEq(vm.activeFork(), mainnetFork);
        string memory name = "nick";
        IPriceOracle.Price memory price = market.getRentPrice(name); // vm.startPrank(0xb8c2C29ee19D8307cb7255e1Cd9CbDE883A267d5);
        uint256 cost = price.base + price.premium;
        market.renew{value: cost}(name);
    }

    // function test_renew() public {
    //     // Ensure the contract is deployed successfully
    //     assertEq(
    //         address(market).balance,
    //         0,
    //         "Initial contract balance should be 0"
    //     );

    //     // Perform a renew with a valid name and sufficient value
    //     string memory validName = "example.eth";
    //     uint256 namePrice = market.CONTROLLER.rentPrice(
    //         validName,
    //         market.renewalDuration()
    //     );
    //     market.renew{value: namePrice}(validName);

    //     // Assert that the renew function was successful
    //     assertEq(
    //         address(market).balance,
    //         namePrice,
    //         "Contract balance should be equal to the name price"
    //     );

    //     // Perform a renew with an invalid name (this should revert)
    //     string memory invalidName = "invalid.eth";
    //     bool success = market.call{value: namePrice}(
    //         abi.encodeWithSignature("renew(string)", invalidName)
    //     );

    //     // Assert that the renew with an invalid name reverted
    //     assertTrue(!success, "Renew with invalid name should revert");
    // }
}
