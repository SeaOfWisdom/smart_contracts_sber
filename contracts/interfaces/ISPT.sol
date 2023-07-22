/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ISPT {
    struct ReaderInfo {
        address readerAddress; // address of reader
        uint64 expires; // expire timestamp
    }

    /*/////////////////
    ///// Events /////
    ///////////////*/

    event NewReader(
        address indexed readerAddress,
        uint256 indexed paperId,
        uint64 expires
    );

    event StatusChanged(uint64 oldStatus, uint64 newStatus);

    event PriceChanged(uint256 oldPrice, uint256 newPrice);

    event ReviewAdded(
        uint256 indexed paperId,
        address indexed reviewerAddress,
        bool decision
    );

    /*////////////////
    /// Functions ///
    ///////////////*/

    //    function setReview(address reviewerAddress, uint8 decision) external;

    function setPrice(uint256 newPrice) external;

    function getReviewers() external view returns (address[] memory);

    function isAuthor(address authorAddress) external view returns (bool);
}
