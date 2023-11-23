// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {ENSMarket} from "../src/ENSMarket.sol";
import {IETHRegistrarController as IETHRC} from "@ensdomains/ethregistrar/IETHRegistrarController.sol";
import {DeployENSMarket} from "../script/DeployENSMarket.s.sol";

contract ENSMarketTest is Test {
    ENSMarket market;
    uint256 duration = 31536000;
    // IETHRC immutable i_IETHRC = IETHRC(0x253553366Da8546fC250F225fe3d25d0C782303b);
    address alice;

    function setUp() public {
        DeployENSMarket deployENSMarket = new DeployENSMarket();
        market = deployENSMarket.run();
        alice = makeAddr("alice");
    }

    function test_available() public {
        string memory name = "nick";
        assertFalse(market.isAvailableName(name));
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
