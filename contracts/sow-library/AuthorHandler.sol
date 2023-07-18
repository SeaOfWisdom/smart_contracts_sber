// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./ParticipantHandler.sol";
import "../paper-factory/PaperFactory.sol";

/// @notice functions require refactoring on adding a new asset
contract AuthorHandler is
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    ParticipantHandler
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    PaperFactory public factory;

    IERC20Upgradeable public sowToken;

    mapping(address => uint256) internal _authorRewards;

    uint256 public maxPercent;
    uint256 public authorPercent;

    uint256[48] private __reserved; // TODO

    function __AuthorHandler_init() internal onlyInitializing {
        __ParticipantHandler_init();

        maxPercent = 10000; // 100.00
        authorPercent = 5000; // 50.00
    }

    /// @dev to add fees
    function becomeAuthor() public {
        address participantAddress = msg.sender;
        Participant storage participant = participants[participantAddress];
        require(participant._address != address(0), "");

        participant._role = Role.Author;
    }

    function claimAuthorRewards() external nonReentrant {
        address author = msg.sender;
        uint256 rewards = _authorRewards[author];
        require(rewards > 0, "ReviewerHandler: null rewards");

        // withdrawal pattern
        _authorRewards[author] = 0;
        require(sowToken.transfer(author, rewards), "Library: transfer failed"); // TODO

        // emit event
    }

    function _addRewardsFor(address author, uint256 amount) internal {}

    function isAuthor(address participant) public view returns (bool) {
        return participants[participant]._address != address(0);
    }

    function getAuthorRewards(address author) public view returns (uint256) {
        return _authorRewards[author];
    }

    function getAuthorWorks(address author) public view returns (SPT[] memory) {
        return factory.getAuthorWorks(author);
    }

    function setToken(address sowTokenAddress) external onlyOwner {
        sowToken = IERC20Upgradeable(sowTokenAddress);
    }

    function setWorkFactory(address workFactoryAddress) external onlyOwner {
        factory = PaperFactory(workFactoryAddress);
    }
}
