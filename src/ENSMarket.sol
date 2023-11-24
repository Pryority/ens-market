// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IPriceOracle} from "@ensdomains/ethregistrar/IPriceOracle.sol";
import {IETHRegistrarController as IETHRC} from "@ensdomains/ethregistrar/IETHRegistrarController.sol";
import {INameWrapper as INW} from "@ensdomains/wrapper/INameWrapper.sol";
import {IBaseRegistrar as IBR} from "@ensdomains/ethregistrar/IBaseRegistrar.sol";

error ResolverRequiredWhenDataSupplied();
error InsufficientValue();

/**
 * @title EN$Market
 */
contract ENSMarket {
    /**
     * @notice The ENS name renewal duration in seconds.
     */
    uint256 constant RENEWAL_DURATION = 31536000;
    uint256 public constant MIN_REGISTRATION_DURATION = 28 days;
    bytes32 private constant ETH_NODE =
        0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;
    uint64 private constant MAX_EXPIRY = type(uint64).max;

    IETHRC public immutable i_IETHRC;
    INW public immutable i_INW;
    IBR immutable i_IBR;
    mapping(bytes32 => uint256) public commitments;

    constructor(address _IETHERC, address _INW, address _IBR) payable {
        i_IETHRC = IETHRC(_IETHERC);
        i_INW = INW(_INW);
        i_IBR = IBR(_IBR);
    }

    function register(
        string calldata name,
        address owner,
        uint256 duration,
        bytes32 secret,
        address resolver,
        bytes[] calldata data,
        bool reverseRecord,
        uint16 ownerControlledFuses
    ) public payable {
        IPriceOracle.Price memory price = getRentPriceInternal(name);

        uint256 cost = price.base + price.premium;

        if (msg.value < cost) {
            revert InsufficientValue();
        }

        i_IETHRC.register{value: msg.value}(
            name,
            owner,
            duration,
            secret,
            resolver,
            data,
            reverseRecord,
            ownerControlledFuses
        );
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

    function commit(bytes32 commitHash) public payable {
        i_IETHRC.commit(commitHash);
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
            RENEWAL_DURATION
        );

        uint256 cost = namePrice.base + namePrice.premium;

        require(msg.value >= (cost), "insufficient funds for renewal");
        i_IETHRC.renew{value: cost}(name, RENEWAL_DURATION);
    }

    /**
     * @notice View prie to rent an ENS name.
     * @param name The ENS name to rent.
     * @return Price from the ENS: PriceOracle to rent name for `RENEWAL_DURATION`
     * @dev When calling, must provide msg.value greater than or equal to rent price of Price Oracle
     */
    function getRentPrice(
        string calldata name
    ) external view returns (IPriceOracle.Price memory) {
        return i_IETHRC.rentPrice(name, RENEWAL_DURATION);
    }

    function getRentPriceInternal(
        string calldata name
    ) internal view returns (IPriceOracle.Price memory) {
        return i_IETHRC.rentPrice(name, RENEWAL_DURATION);
    }

    /**
     * @notice To receive ETH payments.
     */
    receive() external payable {}
}
