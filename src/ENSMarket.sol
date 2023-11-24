// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IPriceOracle} from "@ensdomains/ethregistrar/IPriceOracle.sol";
import {IETHRegistrarController as IETHRC} from "@ensdomains/ethregistrar/IETHRegistrarController.sol";
error ResolverRequiredWhenDataSupplied();

/**
 * @title EN$Market
 */
contract ENSMarket {
    /**
     * @notice The ENS name renewal duration in seconds.
     */
    uint256 constant renewalDuration = 31536000;
    IETHRC immutable i_IETHRC;

    constructor(address _IETHERC) payable {
        i_IETHRC = IETHRC(_IETHERC);
    }

    function createCommitment(
        string memory name,
        address owner,
        uint256 duration,
        bytes32 secret,
        address resolver,
        bytes[] calldata data,
        bool reverseRecord,
        uint16 ownerControlledFuses
    ) external pure returns (bytes32) {
        bytes32 label = keccak256(bytes(name));
        if (data.length > 0 && resolver == address(0)) {
            revert ResolverRequiredWhenDataSupplied();
        }
        return
            keccak256(
                abi.encode(
                    label,
                    owner,
                    duration,
                    secret,
                    resolver,
                    data,
                    reverseRecord,
                    ownerControlledFuses
                )
            );
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
     * @notice Check if several individual ENS names are available.
     * @param names The ENS names to check.
     * @return Array of bool (bool[]), each item T/F based on availability of each name in `names`.
     */
    function isEachAvailableNames(
        string[] calldata names
    ) external returns (bool[] memory) {
        bool[] memory available = new bool[](names.length);

        for (uint256 i = 0; i < names.length; i++) {
            available[i] = i_IETHRC.available(names[i]);
        }

        return available;
    }

    /**
     * @notice Check if several ENS names are available at once.
     * @param names The ENS names to check.
     * @return bool T/F if all names[i] available
     */
    function isAllAvailableNames(
        string[] calldata names
    ) external returns (bool) {
        for (uint256 i = 0; i < names.length; i++) {
            i_IETHRC.available(names[i]);
        }
    }

    /**
     * @notice Renew an ENS name.
     * @param name The ENS name to renew.
     * @dev When calling, must provide msg.value greater than or equal to rent price of Price Oracle
     */
    function renew(string calldata name) external payable {
        IPriceOracle.Price memory namePrice = i_IETHRC.rentPrice(
            name,
            renewalDuration
        );

        uint256 cost = namePrice.base + namePrice.premium;

        require(msg.value >= (cost), "insufficient funds for renewal");
        i_IETHRC.renew{value: cost}(name, renewalDuration);
    }

    /**
     * @notice View prie to rent an ENS name.
     * @param name The ENS name to rent.
     * @return Price from the ENS: PriceOracle to rent name for `renewalDuration`
     * @dev When calling, must provide msg.value greater than or equal to rent price of Price Oracle
     */
    function getRentPrice(
        string calldata name
    ) external view returns (IPriceOracle.Price memory) {
        return i_IETHRC.rentPrice(name, renewalDuration);
    }

    /**
     * @notice To receive ETH payments.
     */
    receive() external payable {}
}
