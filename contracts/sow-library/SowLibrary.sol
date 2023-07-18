// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "../paper-factory/PaperFactory.sol";

import "./ReviewerHandler.sol";

import "hardhat/console.sol";

contract SowLibrary is ReviewerHandler {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint64 public expires;

    function initialize() external initializer {
        __ReviewerHandler_init();
    }

    function publishWork(
        address[] memory authorAddressese,
        string calldata name,
        string memory _workURI,
        uint256 workId
    ) public onlyOwner {
        require(workId > 0, "SowLibrary: work id is zero");
        // check whether the work exists
        for (uint256 i = 0; i < authorAddressese.length; i++) {
            address author = authorAddressese[i];
            require(isAuthor(author), "SowLibrary: author is not registrated");
        }

        // mint NFT
        SPT work = SPT(
            factory.deployNewPaper(authorAddressese, name, _workURI, workId)
        );

        // for (uint256 i = 0; i < authorAddressese.length; i++) {
        //     work.setUser(workId, authorAddressese[i], type(uint64).max);
        // }
    }

    function purchaseWork(uint256 workId) public {
        address reader = msg.sender;
        // get work's entities
        SPT work = factory.getWorkByID(workId);
        require(work.status() == 2, "SowLibrary: paper is not readable");

        uint256 price = work.price();
        require(
            sowToken.transferFrom(reader, address(this), price),
            "SowLibrary: transferFrom failed"
        );

        uint256 authorsRewards = price / 2;
        address[] memory authorAddresses = factory.getWorkAuthors(workId);
        for (uint8 i = 0; i < authorAddresses.length; i++) {
            // transfer some tokens to the author
            require(
                sowToken.transfer(
                    authorAddresses[i],
                    authorsRewards / authorAddresses.length
                ),
                "Library: transfer failed"
            );
        }
        // add rewards for the reviewes
        _addReviewersRewardsForWork(workId, 100); // TODO
        // make the paper readable for the buyer
        work.setReader(reader, expires);

        // emit
    }

    function getWorksByAuthor(
        address authorAddress
    ) public view returns (SPT[] memory) {
        return factory.getAuthorWorks(authorAddress);
    }

    // /// @dev See {IERC165-supportsInterface}.
    // function supportsInterface(
    //     bytes4 interfaceId
    // ) public view virtual returns (bool) {
    //     return
    //         interfaceId == type(IERC4907).interfaceId ||
    //         super.supportsInterface(interfaceId);
    // }

    // function getMyWorks(
    //     address readerAddress
    // ) public view returns (ERC4907[] memory) {
    //     return factory.getAuthorWorks(authorAddress);
    // }
}
