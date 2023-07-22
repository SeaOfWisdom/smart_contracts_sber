/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IPaperHandler {
    event SowTokenChanged(address prevAddress, address newAddress);

    event FactoryChanged(address prevAddress, address newAddress);
}
