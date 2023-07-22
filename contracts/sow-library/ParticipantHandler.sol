// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "../interfaces/IParticipantHandler.sol";

import "./PaperHandler.sol";

contract ParticipantHandler is PaperHandler, IParticipantHandler {
    address[] participantAddresses;
    mapping(address => Participant) participants;

    uint256[48] private __reserved;

    modifier onlyAdmin() {
        require(
            participants[msg.sender]._role == Role.Admin,
            "SowLibrary: only admin allowed"
        );
        _;
    }

    function __ParticipantHandler_init() internal onlyInitializing {
        __PaperHandler_init();
    }

    function join() public {
        address newParticipant = msg.sender;
        require(
            participants[newParticipant]._address == address(0),
            "SowLibrary: participant already exists"
        );

        participants[newParticipant] = Participant({
            _address: newParticipant,
            _role: Role.Reader
        });

        emit RoleChanged(newParticipant, Role.Guest, Role.Reader);
    }

    function addParticipant(address participantAddress) public onlyOwner {
        require(
            participants[participantAddress]._address == address(0),
            "SowLibrary: participant already exists"
        );

        participants[participantAddress] = Participant({
            _address: participantAddress,
            _role: Role.Reader
        });

        emit RoleChanged(participantAddress, Role.Guest, Role.Reader);
    }

    function getRole(address participantAddress) external view returns (Role) {
        return participants[participantAddress]._role;
    }

    function makeAdmin(address participantAddress) external onlyOwner {
        Participant storage participant = participants[participantAddress];

        emit RoleChanged(participantAddress, participant._role, Role.Admin);
        participant._role = Role.Admin;
    }
}
