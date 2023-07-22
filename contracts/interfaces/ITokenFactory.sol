/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ITokenFactory {
    /*/////////////////
    ///// Events /////
    ///////////////*/

    event LibraryChanged(address prevAddress, address newAddress);

    event SPTDeployed(address owner, address tokenContract);
}
