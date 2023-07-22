// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import "../tokens/SPT.sol";
import "../interfaces/ITokenFactory.sol";

contract TokenFactory is OwnableUpgradeable, ITokenFactory {
    address public minter;

    SPT[] public tokens;

    modifier onlyMinter() {
        require(msg.sender == minter);
        _;
    }

    function initialize(address minterAddress) external initializer {
        __Ownable_init();

        minter = minterAddress;
    }

    function deployNewToken(
        address[] memory authorAddresses,
        string memory _contractName,
        string memory _tokenURI,
        uint256 tokenId,
        uint256 initTokenPrice
    ) public onlyMinter returns (address) {
        address token = address(
            new SPT(
                minter,
                authorAddresses,
                _contractName,
                _contractName,
                tokenId,
                _tokenURI,
                initTokenPrice // init paper price
            )
        );
        tokens.push(SPT(token));

        emit SPTDeployed(minter, token);

        return token;
    }

    function getTokens() public view returns (SPT[] memory) {
        return tokens;
    }

    function setMinter(address minterAddress) external {
        emit LibraryChanged(minter, minterAddress);
        minter = minterAddress;
    }
}
