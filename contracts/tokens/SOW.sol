// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "../interfaces/ISOW.sol";

contract SOW is Initializable, OwnableUpgradeable, ERC20Upgradeable, ISOW {
    address public minter;

    modifier onlyMinter() {
        require(msg.sender == minter, "SOW: only minter allowed");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    // constructor() {
    //     _disableInitializers();
    // }

    function initialize() public initializer {
        __ERC20_init("Sea of Wisdom Token", "SOW");
        __Ownable_init();
        minter = msg.sender;
        emit MinterChanged(address(0), minter);
    }

    function mint(address account, uint256 amount) public onlyMinter {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public onlyMinter {
        _burn(account, amount);
    }

    function airdrop(
        address[] memory recipients,
        uint256[] memory amounts
    ) public onlyOwner {
        uint256 numberOfRecipients = recipients.length;
        require(amounts.length == numberOfRecipients, "");
        for (uint256 i = 0; i < numberOfRecipients; ++i) {
            _mint(recipients[i], amounts[i]);
        }
    }

    function changeMinter(address newAddress) external onlyOwner {
        require(newAddress != address(0), "SOW: newAddress is zero");
        address prevAddress = minter;
        minter = newAddress;
        emit MinterChanged(prevAddress, newAddress);
    }
}
