// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import "../interfaces/ISPT.sol";

import "hardhat/console.sol";

/// @notice Scientific Paper Token
contract SPT is ERC721URIStorage, ISPT {
    uint256 public id;
    uint256 public price;

    address[] public authors;
    address[] public reviewers;

    uint64 public totalReadings;

    /// @dev 0 - not approved yet; 1 -- declined; 2 -- approved
    uint64 public status;

    uint64 reviews;

    mapping(address => ReaderInfo) internal _users;

    modifier onlyOwner() {
        require(ownerOf(id) == msg.sender, "SPT: owner not allowed");
        _;
    }

    constructor(
        address owner_,
        address[] memory authorAddresses,
        string memory name_,
        string memory symbol_,
        uint256 paperId_,
        string memory tokenURI_,
        uint256 initPrice
    ) ERC721(name_, symbol_) {
        require(initPrice > 0, "SPT: initial price is zero");
        _setAuthors(authorAddresses);

        _mint(owner_, paperId_);
        _setTokenURI(paperId_, tokenURI_);

        id = paperId_;
        price = initPrice;
    }

    /// @param readerAddress The new reader of the paper
    /// @param expires  UNIX timestamp, The new user could use the NFT before expires
    function setReader(address readerAddress, uint64 expires) public virtual {
        require(
            _isApprovedOrOwner(msg.sender, id),
            "ERC721: transfer caller is not owner nor approved"
        );
        ReaderInfo storage info = _users[readerAddress];
        info.readerAddress = readerAddress;
        info.expires = expires;
        totalReadings++;

        emit NewReader(readerAddress, id, expires);
    }

    /// @notice Get the user address of an NFT
    /// @dev The zero address indicates that there is no user or the user is expired
    ///// @param account The NFT to get the user address for TODO
    /// @return The user address for this NFT
    function isReadableFor(
        address readerAddress
    ) public view virtual returns (bool) {
        if (uint256(_users[readerAddress].expires) >= block.timestamp) {
            return true;
        } else if (isReviewer(readerAddress)) {
            return true;
        } else if (isReviewer(readerAddress)) {
            return true;
        }
        return false;
    }

    function isReviewer(address reviewerAddress) public view returns (bool) {
        for (uint8 i = 0; i < reviewers.length; i++) {
            if (reviewerAddress == reviewers[i]) {
                return true;
            }
        }
        return false;
    }

    function isAuthor(address authorAddress) public view returns (bool) {
        for (uint8 i = 0; i < authors.length; i++) {
            if (authorAddress == authors[i]) {
                return true;
            }
        }
        return false;
    }

    /// @notice Get the user expires of an NFT
    /// @dev The zero value indicates that there is no user
    /// @param account The NFT to get the user expires for // TODO
    /// @return The user expires for this NFT
    function readerExpires(
        address account
    ) public view virtual returns (uint256) {
        return _users[account].expires;
    }

    function getAuthors() public view returns (address[] memory) {
        return authors;
    }

    function getReviewers() public view override returns (address[] memory) {
        return reviewers;
    }

    function getTotalReadings() external view returns (uint256) {
        return uint256(totalReadings);
    }

    function _setAuthors(address[] memory authorAddresses) internal virtual {
        uint8 numberOfAuthors = uint8(authorAddresses.length);
        require(
            numberOfAuthors > 0 && numberOfAuthors < type(uint8).max,
            "SPT: number of author is wrong"
        );
        authors = authorAddresses;
    }

    // TODO
    function setReview(
        address reviewerAddress,
        bool decision
    ) public onlyOwner {
        uint8 reviewerIndex = uint8(reviewers.length);
        reviewers.push(reviewerAddress);
        // positive
        if (decision) {
            reviews = reviews | (uint8(1) << reviewerIndex);
        }

        emit ReviewAdded(id, reviewerAddress, decision);
    }

    function getReviewerDecision(
        address reviewerAddress
    ) public view returns (bool) {
        uint8 i = 0;
        for (i; i < reviewers.length; i++) {
            if (reviewerAddress == reviewers[i]) {
                break;
            }
        }
        uint256 mask = (1 << i);

        return reviews & mask == mask;
    }

    function setStatus(uint64 newStatus) external onlyOwner {
        emit StatusChanged(status, newStatus);
        status = newStatus;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        emit PriceChanged(price, newPrice);
        price = newPrice;
    }
}
