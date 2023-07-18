// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract ParticipantHandler is
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    enum Role {
        Guest,
        Reader,
        Author,
        Reviewer,
        Advisor,
        Admin
    }

    struct Participant {
        address _address;
        Role _role;
    }

    address[] participantAddresses;
    mapping(address => Participant) participants;

    uint256[49] private __reserved;

    modifier onlyAdmin() {
        require(participants[msg.sender]._role == Role.Admin, ""); // TODO
        _;
    }

    function __ParticipantHandler_init() internal onlyInitializing {
        __Ownable_init();
    }

    function join() public {
        address newParticipant = msg.sender;
        require(participants[msg.sender]._address == address(0), ""); // TODO

        participants[newParticipant] = Participant({
            _address: newParticipant,
            _role: Role.Reader
        });

        // emit event
    }

    function getRole(address participantAddress) external view returns (Role) {
        return participants[participantAddress]._role;
    }

    function makeAdmin(address participantAddress) external onlyOwner {
        participants[participantAddress]._role = Role.Admin;
    }

    function _makeReviewer(address newReviewer) internal {
        Participant storage participant = participants[newReviewer];
        require(participant._address != address(0), "");
        participant._role = Role.Reviewer;
    }
}
