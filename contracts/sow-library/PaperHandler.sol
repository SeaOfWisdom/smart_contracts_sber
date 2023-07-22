// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "../token-factory/TokenFactory.sol";
import "../interfaces/IPaperHandler.sol";

contract PaperHandler is
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    IPaperHandler
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    TokenFactory public factory;

    IERC20Upgradeable public sowToken;

    // author => paper ids
    mapping(address => SPT[]) authorPapers;

    // mapping(uint256 => address[]) paperAuthors;
    mapping(uint256 => address) public paperIdToAddress; //index to contract address mapping

    uint256[46] private __reserved;

    function __PaperHandler_init() internal onlyInitializing {
        __Ownable_init();
    }

    function getPaperById(uint256 paperId) public view returns (SPT) {
        return SPT(paperIdToAddress[paperId]);
    }

    function _transferSowToken(address to, uint256 amount) internal {
        require(sowToken.transfer(to, amount), "SowLibrary: transfer failed");
    }

    function _transferFromSowToken(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(
            sowToken.transferFrom(from, to, amount),
            "SowLibrary: transferFrom failed"
        );
    }

    function setSowToken(address sowTokenAddress) external onlyOwner {
        emit SowTokenChanged(address(sowToken), sowTokenAddress);
        sowToken = IERC20Upgradeable(sowTokenAddress);
    }

    function setFactory(address factoryAddress) external onlyOwner {
        emit FactoryChanged(address(factory), factoryAddress);
        factory = TokenFactory(factoryAddress);
    }
}
