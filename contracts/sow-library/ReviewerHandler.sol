// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "./AuthorHandler.sol";

/// @notice functions require refactoring on adding a new asset
contract ReviewerHandler is
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    AuthorHandler
{
    using ECDSAUpgradeable for bytes32;

    uint256 public reviewerDepositAmount;

    mapping(address => uint256) internal _reviewerDeposits;

    mapping(uint256 => mapping(address => uint256)) internal _reviewerRewards;

    struct Review {
        address reviewer;
        uint256 workID;
        uint256 status;
    }

    uint256[47] private __reserved;

    function __ReviewerHandler_init() internal onlyInitializing {
        __AuthorHandler_init();

        reviewerDepositAmount = 50 ether;
    }

    function becomeReviewer() public {
        address participantAddress = msg.sender;
        _makeReviewer(participantAddress);

        require(
            sowToken.transferFrom(
                participantAddress,
                address(this),
                reviewerDepositAmount
            ),
            "Library: transferFrom failed"
        ); // TODO

        //
    }

    // function _addReviewerRewards(
    //     uint256 workId,
    //     uint128 newStatus
    // ) external onlyOwner {
    //     SPT work = factory.getWorkByID(workId);
    //     work.setStatus(newStatus);

    //     // emit
    // }

    function claimReviewerRewards(uint256 workId) external nonReentrant {
        address reviewer = msg.sender;
        require(
            isAbleToClaimForWork(workId, reviewer),
            "ReviewerHandler: rewards is zero"
        );

        uint256 rewards = _reviewerRewards[workId][reviewer];
        delete _reviewerRewards[workId][reviewer];

        require(
            sowToken.transfer(reviewer, rewards),
            "Library: transfer failed"
        ); // TODO
    }

    function isAbleToClaimForWork(
        uint256 workId,
        address reviewerAddress
    ) public view returns (bool) {
        uint256 rewards = _reviewerRewards[workId][reviewerAddress];
        if (rewards == 0) {
            return false;
        }
        // get work's readings
        SPT work = factory.getWorkByID(workId);
        if (work.getTotalReadings() < 10) {
            return false;
        }
        return true;
    }

    function getReviewerRewardsForWork(
        uint256 workId,
        address reviewerAddress
    ) public view returns (uint256) {
        return _reviewerRewards[workId][reviewerAddress];
    }

    function _addReviewersRewardsForWork(
        uint256 workId,
        uint256 rewards
    ) internal {
        SPT work = factory.getWorkByID(workId);
        require(
            work.status() == 2,
            "SowLibrary: work status is not appropriate"
        );

        address[] memory reviewers = work.getReviewers();
        for (uint8 i = 0; i < reviewers.length; i++) {
            _reviewerRewards[workId][reviewers[i]] += rewards;
        }
    }

    function addReviewsForWork(
        uint256 workId,
        address[] memory reviewerAddresses,
        uint8[] memory reviews
    ) external nonReentrant onlyOwner {
        uint256 numberOfReviewers = reviewerAddresses.length;
        require(
            numberOfReviewers == reviews.length,
            "SowLibrary: inconsistent input data"
        );

        SPT work = factory.getWorkByID(workId);
        require(
            work.status() == 0,
            "SowLibrary: work status is not appropriate"
        );

        uint256 totalVotes;
        for (uint8 i = 0; i < reviews.length; i++) {
            address reviewerAddress = reviewerAddresses[i];
            uint8 decision = reviews[i];
            if (decision == 0 || reviewerAddress == address(0)) {
                continue;
            }
            if (!isReviewer(reviewerAddress)) {
                continue;
            }
            work.setReviews(reviewerAddress, decision);
            totalVotes += decision;
        }
        console.log("totalVotes: ", totalVotes);
        // n=3 -> ? > 6*2/3 = 4
        if (
            totalVotes * maxPercent >= (4 * numberOfReviewers * maxPercent) / 3
        ) {
            work.setStatus(2); // approved
        } else {
            work.setStatus(1); // declined
        }
    }

    function publishReviewsBatch(
        uint256 workId,
        string[] calldata reviews,
        bytes[] calldata reviewSignatures
    ) external nonReentrant onlyOwner {
        require(reviews.length == reviewSignatures.length, "SowLibrary: "); // TODO

        SPT work = factory.getWorkByID(workId);
        require(work.status() == 0, "SowLibrary: work has the wrong status");

        // go throw reviews and verify each of them
        for (uint8 i = 0; i < reviews.length; i++) {
            bytes32 signedMessageHash = keccak256(abi.encode(reviews[i]))
                .toEthSignedMessageHash();

            console.log(
                " isReviewer(signedMessageHash.recover(reviewSignatures[i]): ",
                signedMessageHash.recover(reviewSignatures[i])
            );

            require(
                isReviewer(signedMessageHash.recover(reviewSignatures[i])),
                "SowLibrary: signer is not reviewer"
            );
        }
    }

    // function updatePaperStatus(
    //     uint256 workId,
    //     uint128 newStatus
    // ) external onlyOwner {
    //     SPT work = factory.getWorkByID(workId);
    //     work.setStatus(newStatus);

    //     // emit
    // }

    function isReviewer(address reviewerAddress) public view returns (bool) {
        return _reviewerDeposits[reviewerAddress] > 0;
    }
}
