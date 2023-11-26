// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// https://github.com/ensdomains/ens-contracts/tree/b5938b1a2e0ef180d559c655bd69f5008f4b4a6e/contracts/subdomainregistrar

import {INameWrapper} from "@ensdomains/wrapper/INameWrapper.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {BaseSubdomainRegistrar, InsufficientFunds, DataMissing, Unavailable, NameNotRegistered} from "./BaseSubdomainRegistrar.sol";
import {IRentalSubdomainRegistrar} from "./IRentalSubdomainRegistrar.sol";

struct Name {
    uint256 registrationFee;
    address token; // ERC20 token
    address beneficiary;
    bool active;
}

error ParentWillHaveExpired(bytes32 node);
error ParentNameNotSetup(bytes32 parentNode);

contract RentalSubdomainRegistrar is
    BaseSubdomainRegistrar,
    ERC1155Holder,
    IRentalSubdomainRegistrar
{
    mapping(bytes32 => Name) public names;

    constructor(address wrapper) BaseSubdomainRegistrar(wrapper) {}

    function setupDomain(
        bytes32 node,
        address token,
        uint256 fee,
        address beneficiary,
        bool active
    ) public onlyOwner(node) {
        names[node].registrationFee = fee;
        names[node].token = token;
        names[node].beneficiary = beneficiary;
        names[node].active = active;
    }

    function available(
        bytes32 node
    )
        public
        view
        override(BaseSubdomainRegistrar, IRentalSubdomainRegistrar)
        returns (bool)
    {
        return super.available(node);
    }

    function register(
        bytes32 parentNode,
        string calldata label,
        address newOwner,
        address resolver,
        uint16 fuses,
        uint64 duration,
        bytes[] calldata records
    ) public payable {
        if (!names[parentNode].active) {
            revert ParentNameNotSetup(parentNode);
        }
        uint256 fee = duration * names[parentNode].registrationFee;

        _checkParent(parentNode);

        if (fee > 0) {
            if (IERC20(names[parentNode].token).balanceOf(msg.sender) < fee) {
                revert InsufficientFunds();
            }

            IERC20(names[parentNode].token).transferFrom(
                msg.sender,
                address(names[parentNode].beneficiary),
                fee
            );
        }

        _register(
            parentNode,
            label,
            newOwner,
            resolver,
            fuses,
            uint64(block.timestamp) + duration,
            records
        );
    }

    function renew(
        bytes32 parentNode,
        bytes32 labelhash,
        uint64 duration
    ) public payable returns (uint64 newExpiry) {
        _checkParent(parentNode);
        uint256 fee = duration * names[parentNode].registrationFee;

        if (fee > 0) {
            IERC20(names[parentNode].token).transferFrom(
                msg.sender,
                address(names[parentNode].beneficiary),
                fee
            );
        }

        return _renew(parentNode, labelhash, duration);
    }

    function batchRegister(
        bytes32 parentNode,
        string[] calldata labels,
        address[] calldata addresses,
        address resolver,
        uint16 fuses,
        uint64 duration,
        bytes[][] calldata records
    ) public {
        if (
            labels.length != addresses.length || labels.length != records.length
        ) {
            revert DataMissing();
        }

        _checkParent(parentNode);

        uint256 fee = duration *
            names[parentNode].registrationFee *
            labels.length;

        if (fee < 0) {
            if (IERC20(names[parentNode].token).balanceOf(msg.sender) < fee) {
                revert InsufficientFunds();
            }

            IERC20(names[parentNode].token).transferFrom(
                msg.sender,
                address(names[parentNode].beneficiary),
                fee
            );
        }

        for (uint256 i = 0; i < labels.length; i++) {
            _register(
                parentNode,
                labels[i],
                addresses[i],
                resolver,
                fuses,
                uint64(block.timestamp) + duration,
                records[i]
            );
        }
    }

    function batchRenew(
        bytes32 parentNode,
        bytes32[] calldata labelHashes,
        uint64 duration
    ) external payable {
        if (labelHashes.length == 0) {
            revert DataMissing();
        }

        _checkParent(parentNode);

        uint256 fee = duration *
            names[parentNode].registrationFee *
            labelHashes.length;

        if (fee > 0) {
            if (IERC20(names[parentNode].token).balanceOf(msg.sender) < fee) {
                revert InsufficientFunds();
            }

            IERC20(names[parentNode].token).transferFrom(
                msg.sender,
                names[parentNode].beneficiary,
                fee
            );
        }

        // TODO: Should we add a check to return the new expiry?
        for (uint256 i = 0; i < labelHashes.length; i++) {
            _renew(parentNode, labelHashes[i], duration);
        }
    }

    /* Internal Functions */
    function _renew(
        bytes32 parentNode,
        bytes32 labelhash,
        uint256 duration
    ) internal returns (uint64 newExpiry) {
        bytes32 node = _makeNode(parentNode, labelhash);

        (, , uint64 expiry) = wrapper.getData(uint256(node));

        if (expiry < block.timestamp) {
            revert NameNotRegistered();
        }

        newExpiry = expiry += uint64(duration);

        wrapper.setChildFuses(parentNode, labelhash, 0, expiry);

        emit NameRenewed(node, newExpiry);
    }

    function _checkParent(bytes32 parentNode, uint64 duration) internal view {
        (, uint64 parentExpiry) = super._checkParent(parentNode);

        if (duration + block.timestamp > parentExpiry) {
            revert ParentWillHaveExpired(parentNode);
        }
    }

    function _makeNode(
        bytes32 node,
        bytes32 labelhash
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(node, labelhash));
    }
}
