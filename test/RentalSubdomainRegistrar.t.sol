// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {RentalSubdomainRegistrar as RSR} from "../src/RentalSubdomainRegistrar.sol";
import {IPriceOracle} from "@ensdomains/ethregistrar/IPriceOracle.sol";
import {ENSMarket} from "../src/ENSMarket.sol";
import {DeployRentalSubdomainRegistrar} from "../script/DeployRentalSubdomainRegistrar.s.sol";
import {ENSMarket} from "../src/ENSMarket.sol";

contract RentalSubdomainRegistrarTest is Test {
    RSR rentalSubRegistrar;
    ENSMarket market;
    address alice = makeAddr("alice");

    struct Commitment {
        bytes32 label;
        address owner;
        uint256 duration;
        bytes32 secret;
        address resolver;
        bytes[] data;
        bool reverseRecord;
        uint16 ownerControlledFuses;
    }

    function setUp() public {
        DeployRentalSubdomainRegistrar deployedRentalSubdomainRegistrar = new DeployRentalSubdomainRegistrar();
        rentalSubRegistrar = deployedRentalSubdomainRegistrar.run();
    }

    function test_setupDomain() public {
        vm.startPrank(address(market));

        // ARRANGE
        bytes32 node = keccak256(bytes("my-cool-ens-name-123"));
        address token = 0x0000000000000000000000000000000000000000;
        uint256 fee = 0.01 ether;
        address beneficiary = alice;
        bool active = false;

        // ACT
        rentalSubRegistrar.setupDomain(node, token, fee, beneficiary, active);

        // ASSERT
        (
            uint256 expectedRegistrationFee,
            address expectedToken,
            address expectedBeneficiary,
            bool expectedActive
        ) = rentalSubRegistrar.names(node);

        vm.stopPrank();

        assertEq(fee, expectedRegistrationFee);
        assertEq(token, expectedToken);
        assertEq(beneficiary, expectedBeneficiary);
        assertEq(active, expectedActive);
    }
}

// Structure Guidelines for Testing:
// ARRANGE
// ACT
// ASSERT
