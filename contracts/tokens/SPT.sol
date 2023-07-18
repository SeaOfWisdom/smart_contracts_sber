// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import "hardhat/console.sol";

/// @notice Scientific Paper Token
contract SPT is ERC721URIStorage {
    uint256 public workId;

    uint256 public price;

    address[] public authors;

    address[] public reviewers;

    uint64 public totalReadings;

    /// @dev 0 - not approved yet; 2 -- approved; 1 -- declined
    uint128 public status;

    struct ReaderInfo {
        address account; // address of user role
        uint64 expires; // unix timestamp, user expires
    }

    mapping(address => ReaderInfo) internal _users;

    modifier onlyOwner() {
        require(ownerOf(workId) == msg.sender, "SPT: owner not allowed");
        _;
    }

    constructor(
        address owner_,
        address[] memory authorAddresses,
        string memory name_,
        string memory symbol_,
        uint256 workId_,
        string memory tokenURI_,
        uint256 initPrice
    ) ERC721(name_, symbol_) {
        require(initPrice > 0, "SPT: initial price is zero");
        _setAuthors(authorAddresses);

        _mint(owner_, workId_);
        _setTokenURI(workId_, tokenURI_);

        workId = workId_;
        price = initPrice;
    }

    /// @notice set the user and expires of a NFT
    /// @dev The zero address indicates there is no user
    /// Throws if `tokenId` is not valid NFT
    /// @param account  The new user of the NFT
    /// @param expires  UNIX timestamp, The new user could use the NFT before expires
    function setReader(address account, uint64 expires) public virtual {
        require(
            _isApprovedOrOwner(msg.sender, workId),
            "ERC721: transfer caller is not owner nor approved"
        );
        ReaderInfo storage info = _users[account];
        info.account = account;
        info.expires = expires;
        totalReadings++;

        //  emit UpdateUser(tokenId, user, expires);
    }

    function setStatus(uint8 newStatus) external onlyOwner {
        status = newStatus;
    }

    /// @notice Get the user address of an NFT
    /// @dev The zero address indicates that there is no user or the user is expired
    ///// @param account The NFT to get the user address for TODO
    /// @return The user address for this NFT
    function isReadableFor(address account) public view virtual returns (bool) {
        if (uint256(_users[account].expires) >= block.timestamp) {
            return true;
        } else {
            return false;
        }
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        // super._beforeTokenTransfer(from, to, tokenId);
        // if (from != to && _users[tokenId].account != address(0)) {
        //     delete _users[tokenId];
        //     //    emit UpdateUser(tokenId, address(0), 0);
        // }
    }

    function getReviewers() public view returns (address[] memory) {
        return reviewers;
    }

    function getTotalReadings() external view returns (uint256) {
        return uint256(totalReadings);
    }

    function _setAuthors(address[] memory authorAddresses) internal virtual {
        uint256 numberOfAuthors = authorAddresses.length;
        require(numberOfAuthors > 0, "");
        authors = authorAddresses;
    }

    function setReviews(
        address reviewerAddress,
        uint8 decision
    ) public onlyOwner {
        reviewers.push(reviewerAddress);
    }
}
