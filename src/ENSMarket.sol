// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IETHRegistrarController as IETHRC} from "@ensdomains/ethregistrar/IETHRegistrarController.sol";

/**
 * @title EN$Market
 * @dev Based on Wary's SelfRepayingENS
 */
contract ENSMarket {
    /**
     * @notice The ENS name renewal duration in seconds.
     */
    uint256 constant renewalDuration = 365 days;
    IETHRC immutable i_IETHRC;

    constructor(address _IETHERC) payable {
        i_IETHRC = IETHRC(_IETHERC);
    }

    /**
     * @notice Check if an ENS name is available.
     * @param name The ENS name to check.
     * @return True if the name is available, false otherwise.
     */
    function isAvailableName(string calldata name) external returns (bool) {
        return i_IETHRC.available(name);
    }

    /**
     * @notice Renew an ENS name.
     * @param name The ENS name to renew.
     */
    // function renew(string calldata name) external payable {
    //     uint256 namePrice = CONTROLLER.rentPrice(name, renewalDuration).amount;
    //     require(msg.value >= namePrice, "Insufficient funds for renewal");
    //     CONTROLLER.renew{value: namePrice}(name, renewalDuration);
    // }

    /**
     * @notice Register an ENS name.
     * @param name The ENS name to register.
     */
    // function register(string calldata name) external payable {
    //     require(CONTROLLER.available(name), "Name is not available");
    //     uint256 namePrice = CONTROLLER.rentPrice(name, renewalDuration).amount;
    //     require(msg.value >= namePrice, "Insufficient funds for registration");
    //     CONTROLLER.register{value: namePrice}(
    //         name,
    //         address(this), // Set the buyer as the registrant
    //         renewalDuration
    //     );
    // }

    /**
     * @notice To receive ETH payments.
     */
    receive() external payable {}
}
