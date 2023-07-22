// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "../interfaces/IAuthorHandler.sol";
import "./ParticipantHandler.sol";

contract AuthorHandler is ParticipantHandler, IAuthorHandler {
    mapping(address => uint256) internal _authorRewards;

    uint256 public maxPercent;
    uint256 public authorPercent;

    uint256[47] private __reserved;

    function __AuthorHandler_init() internal onlyInitializing {
        __ParticipantHandler_init();

        maxPercent = 10000; // 100.00
        authorPercent = 5000; // 50.00
    }

    /// @dev add fees ??
    function becomeAuthor() public {
        address participantAddress = msg.sender;
        Participant storage participant = participants[participantAddress];
        require(
            participant._address != address(0),
            "SowLibrary: there is no participant"
        );

        emit RoleChanged(participantAddress, participant._role, Role.Author);
        participant._role = Role.Author;
    }

    /// @dev to add fees
    function makeAuthor(address participantAddress) external onlyOwner {
        Participant storage participant = participants[participantAddress];
        require(
            participant._address != address(0),
            "SowLibrary: participantAddress is zero"
        );

        emit RoleChanged(participantAddress, participant._role, Role.Author);
        participant._role = Role.Author;
    }

    function claimAuthorRewards() external override nonReentrant {
        address author = msg.sender;
        uint256 rewards = _authorRewards[author];
        require(rewards > 0, "SowLibrary: null rewards");

        // withdrawal pattern
        _authorRewards[author] = 0;
        _transferSowToken(author, rewards);

        emit AuthorRewardsClaimed(author, rewards);
    }

    function _addRewardsFor(address authorAddress, uint256 amount) internal {}

    function isAuthor(address participantAddress) public view returns (bool) {
        return participants[participantAddress]._role > Role.Reader;
    }

    function getAuthorRewards(
        address authorAddress
    ) public view returns (uint256) {
        return _authorRewards[authorAddress];
    }

    function getAuthorPapers(
        address authorAddress
    ) public view returns (SPT[] memory) {
        return authorPapers[authorAddress];
    }
}
