// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./ReviewerHandler.sol";
import "../interfaces/ISowLibrary.sol";

contract SowLibrary is ReviewerHandler, ISowLibrary {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint64 public expires;

    function initialize() external initializer {
        __ReviewerHandler_init();
    }

    function publishPaper(
        address[] calldata authorAddresses,
        string calldata name,
        string calldata paperURI,
        uint256 paperId,
        uint256 paperPrice
    ) public onlyOwner {
        require(paperId > 0, "SowLibrary: paper id is zero");
        require(bytes(name).length != 0, "SowLibrary: name is null");
        require(bytes(paperURI).length != 0, "SowLibrary: paperURI is null");
        // check whether the paper exists with this id
        require(
            address(getPaperById(paperId)) == address(0),
            "SowLibrary: paper already exists"
        );

        for (uint256 i = 0; i < authorAddresses.length; i++) {
            address author = authorAddresses[i];
            require(isAuthor(author), "SowLibrary: author is not registrated");
        }

        address token = factory.deployNewToken(
            authorAddresses,
            name,
            paperURI,
            paperId,
            paperPrice
        );

        paperIdToAddress[paperId] = token;
        for (uint8 i = 0; i < authorAddresses.length; ++i) {
            address author = authorAddresses[i];
            authorPapers[author].push(SPT(token));
        }
    }

    function purchasePaper(uint256 paperId) public {
        address reader = msg.sender;

        SPT token = getPaperById(paperId);
        // TODO
        // require(token.status() == 2, "SowLibrary: paper is not readable");

        uint256 price = token.price();
        _transferFromSowToken(reader, address(this), price);

        uint256 authorsRewards = price / 2;
        address[] memory authorAddresses = token.getAuthors();
        uint256 numberOfAuthors = authorAddresses.length;
        for (uint8 i = 0; i < numberOfAuthors; i++) {
            // transfer some tokens to the author
            _transferSowToken(
                authorAddresses[i],
                authorsRewards / numberOfAuthors
            );
        }
        // add rewards for the reviewes
        //  _addReviewersRewardsForPaper(paperId, 100); // TODO
        // make the paper readable for the buyer
        token.setReader(reader, expires);

        emit PaperPurchased(reader, paperId);
    }
}
