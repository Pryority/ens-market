// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {IETHRegistrarController as IETHRC} from "@ensdomains/ethregistrar/IETHRegistrarController.sol";
import {IPriceOracle} from "@ensdomains/ethregistrar/IPriceOracle.sol";
import {ENSMarket} from "../src/ENSMarket.sol";
import {DeployENSMarket} from "../script/DeployENSMarket.s.sol";

contract ENSMarketTest is Test {
    ENSMarket market;
    address alice;
    // uint256 mainnetFork;

    // string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");

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
        DeployENSMarket deployENSMarket = new DeployENSMarket();
        market = deployENSMarket.run();
        alice = makeAddr("alice");
        // mainnetFork = vm.createFork(MAINNET_RPC_URL);
    }

    function test_createCommitment() public {
        bytes[] memory data = new bytes[](0);

        Commitment memory commitment = Commitment({
            label: bytes32(keccak256(bytes("my_new_name"))),
            owner: alice,
            duration: 31536000,
            secret: bytes32(keccak256(bytes("my_secret"))),
            resolver: address(0),
            data: data,
            reverseRecord: true,
            ownerControlledFuses: 0
        });

        bytes32 commitmentHash = keccak256(
            abi.encode(
                commitment.label,
                commitment.owner,
                commitment.duration,
                commitment.secret,
                commitment.resolver,
                commitment.data,
                commitment.reverseRecord,
                commitment.ownerControlledFuses
            )
        );

        bytes32 expectedCommitmentHash = market.createCommitment(
            "my_new_name",
            commitment.owner,
            commitment.duration,
            commitment.secret,
            commitment.resolver,
            commitment.data,
            commitment.reverseRecord,
            commitment.ownerControlledFuses
        );

        assertEq(commitmentHash, expectedCommitmentHash);
    }

    function test_register() public {
        vm.startPrank(alice);
        vm.deal(alice, 1 ether);
        bytes[] memory data = new bytes[](0);
        string memory name = "my_new_name";

        uint commitTime = block.timestamp;
        emit log_named_uint("Commit Time", commitTime);

        Commitment memory commitment = Commitment({
            label: bytes32(keccak256(bytes(name))),
            owner: alice,
            duration: 31536000,
            secret: bytes32(keccak256(bytes("my_secret"))),
            resolver: address(0),
            data: data,
            reverseRecord: false,
            ownerControlledFuses: 0
        });

        IPriceOracle.Price memory price = market.getRentPrice("my_new_name");
        uint256 cost = price.base + price.premium;

        bytes32 commitHash = market.createCommitment(
            name,
            commitment.owner,
            commitment.duration,
            commitment.secret,
            commitment.resolver,
            commitment.data,
            commitment.reverseRecord,
            commitment.ownerControlledFuses
        );

        market.commit(commitHash);

        // Wait for at least 60 seconds, but less than 86400 seconds
        uint registerTime = commitTime + 61; // You can adjust this time based on your requirements
        vm.warp(registerTime);
        emit log_named_uint("Register Time", registerTime);

        market.register{value: cost}(
            name,
            alice,
            31536000,
            bytes32(keccak256(bytes("my_secret"))),
            address(0),
            data,
            false,
            0
        );

        vm.stopPrank();
    }

    function test_isAllAvailableNames() public {
        string[] memory names = new string[](2);
        names[0] = "nick";
        names[1] = "vitalik";
        assertFalse(market.isAllAvailableNames(names));
    }

    function test_isEachAvailableNames() public {
        // assertEq(vm.activeFork(), mainnetFork);
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
        // assertEq(vm.activeFork(), mainnetFork);
        string memory name = "nick";
        IPriceOracle.Price memory price = market.getRentPrice(name);
        uint256 cost = price.base + price.premium;
        market.renew{value: cost}(name);
    }
}
