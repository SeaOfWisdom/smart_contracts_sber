/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IReviewerHandler {
    event ReviewerRewardsClaimed(address indexed participant, uint256 rewards);
}
