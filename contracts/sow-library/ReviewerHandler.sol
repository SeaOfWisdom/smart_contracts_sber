// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "./AuthorHandler.sol";
import "../interfaces/IReviewerHandler.sol";

/// @notice functions require refactoring on adding a new asset
contract ReviewerHandler is
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    AuthorHandler,
    IReviewerHandler
{
    using ECDSAUpgradeable for bytes32;

    uint256 public reviewerDepositAmount;

    mapping(address => uint256) internal _reviewerDeposits;

    mapping(uint256 => mapping(address => uint256)) internal _reviewerRewards;

    uint8 public minNumReadings;

    uint256[46] private __reserved;

    function __ReviewerHandler_init() internal onlyInitializing {
        __AuthorHandler_init();

        reviewerDepositAmount = 50 ether;
        minNumReadings = 2;
    }

    /// @notice charges reviewer deposit fees(reviewerDepositAmount)
    function becomeReviewer() public {
        address participantAddress = msg.sender;
        _transferFromSowToken(
            participantAddress,
            address(this),
            reviewerDepositAmount
        );

        _makeReviewer(participantAddress);
    }

    /// @dev admin method
    function makeReviewer(address participantAddress) external onlyOwner {
        _makeReviewer(participantAddress);
    }

    function _makeReviewer(address participantAddress) internal {
        Participant storage participant = participants[participantAddress];
        require(
            participant._address != address(0),
            "SowLibrary: there is no participant"
        );

        emit RoleChanged(participantAddress, participant._role, Role.Reviewer);

        participant._role = Role.Reviewer;
    }

    function claimReviewerRewards(uint256 paperId) external nonReentrant {
        address reviewer = msg.sender;
        require(
            isAbleToClaimForPaper(paperId, reviewer),
            "SowLibrary: is not able to claim"
        );

        uint256 rewards = _reviewerRewards[paperId][reviewer];
        delete _reviewerRewards[paperId][reviewer];
        _transferSowToken(reviewer, rewards);

        emit ReviewerRewardsClaimed(reviewer, rewards);
    }

    function isAbleToClaimForPaper(
        uint256 paperId,
        address reviewerAddress
    ) public view returns (bool) {
        uint256 rewards = _reviewerRewards[paperId][reviewerAddress];
        if (rewards == 0) {
            return false;
        }

        SPT token = getPaperById(paperId);
        if (token.getTotalReadings() < minNumReadings) {
            return false;
        }

        return true;
    }

    function getReviewerRewardsForPaper(
        uint256 paperId,
        address reviewerAddress
    ) public view returns (uint256) {
        return _reviewerRewards[paperId][reviewerAddress];
    }

    function _addReviewersRewardsForPaper(
        uint256 paperId,
        uint256 rewards
    ) internal {
        SPT token = getPaperById(paperId);
        require(
            token.status() == 2,
            "SowLibrary: paper status is not appropriate"
        );

        address[] memory reviewers = token.getReviewers();
        for (uint8 i = 0; i < reviewers.length; i++) {
            _reviewerRewards[paperId][reviewers[i]] += rewards;
        }
    }

    function addReviewsForPaper(
        uint256 paperId,
        address[] memory reviewerAddresses,
        uint8[] memory reviews
    ) external nonReentrant onlyOwner {
        uint256 numberOfReviewers = reviewerAddresses.length;
        require(
            numberOfReviewers == reviews.length,
            "SowLibrary: inconsistent input data"
        );

        SPT token = getPaperById(paperId);
        require(
            token.status() == 0,
            "SowLibrary: paper status is not appropriate"
        );

        uint256 totalVotes;
        for (uint8 i = 0; i < reviews.length; i++) {
            address reviewerAddress = reviewerAddresses[i];
            if (token.isAuthor(reviewerAddress)) {
                continue;
            }
            uint8 decision = reviews[i];
            if (decision == 0 || reviewerAddress == address(0)) {
                continue;
            }
            if (!isReviewer(reviewerAddress)) {
                continue;
            }
            //  token.setReview(reviewerAddress, decision);
            totalVotes += decision;
        }

        if (
            totalVotes * maxPercent >= (4 * numberOfReviewers * maxPercent) / 3
        ) {
            token.setStatus(2); // approved
        } else {
            token.setStatus(1); // declined
        }
    }

    function publishReviewsBatch(
        uint256 paperId,
        string[] calldata reviews,
        bytes[] calldata reviewSignatures
    ) external nonReentrant onlyOwner {
        require(
            reviews.length == reviewSignatures.length,
            "SowLibrary: inconsistent input data"
        );

        SPT token = getPaperById(paperId);
        require(token.status() == 0, "SowLibrary: paper has the wrong status");

        // go throw reviews and verify each of them
        for (uint8 i = 0; i < reviews.length; i++) {
            bytes32 signedMessageHash = keccak256(abi.encode(reviews[i]))
                .toEthSignedMessageHash();

            require(
                isReviewer(signedMessageHash.recover(reviewSignatures[i])),
                "SowLibrary: signer is not reviewer"
            );
        }
    }

    function isReviewer(address reviewerAddress) public view returns (bool) {
        return _reviewerDeposits[reviewerAddress] >= reviewerDepositAmount;
    }
}
