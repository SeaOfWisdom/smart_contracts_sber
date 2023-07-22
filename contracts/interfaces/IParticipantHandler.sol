/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IParticipantHandler {
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

    event RoleChanged(address indexed participant, Role prevRole, Role newRole);
}
