/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAuthorHandler {
    /*/////////////////
    ///// Events /////
    ///////////////*/

    event AuthorRewardsClaimed(address indexed participant, uint256 rewards);

    /*////////////////
    /// Functions ///
    ///////////////*/

    function claimAuthorRewards() external;
}
