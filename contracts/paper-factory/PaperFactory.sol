// contracts/FactoryERC1155.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../tokens/ERC1155Token.sol";
import "../tokens/SPT.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract PaperFactory is OwnableUpgradeable {
    address private _libraryAddress;

    SPT[] public works; //an array that contains different ERC1155 tokens deployed
    // author => works ids
    mapping(address => SPT[]) authorWorks;
    // author => work idx
    mapping(uint256 => address[]) workAuthors;
    mapping(uint256 => address) public workIdToContract; //index to contract address mapping
    // mapping(uint256 => address) public workIdToOwner; //index to ERC1155 owner address

    modifier onlyLibrary() {
        require(msg.sender == _libraryAddress);
        _;
    }

    event ERC1155Created(address owner, address tokenContract); //emitted when ERC1155 token is deployed
    event ERC1155Minted(address owner, address tokenContract, uint amount); //emmited when ERC1155 token is minted

    function initialize() external initializer {
        __Ownable_init();
    }

    function deployNewPaper(
        address[] memory authorAddresses,
        string memory _contractName,
        string memory _workURI,
        uint256 workId
    ) public onlyLibrary returns (address) {
        SPT work = new SPT(
            _libraryAddress,
            authorAddresses,
            _contractName,
            _contractName,
            workId,
            _workURI,
            50 ether // init work price
        );
        works.push(SPT(work));

        workIdToContract[workId] = address(work);

        // workIdToOwner[works.length - 1] = _libraryAddress;

        for (uint8 i = 0; i < authorAddresses.length; ++i) {
            address author = authorAddresses[i];
            authorWorks[author].push(work);
            workAuthors[workId].push(author);
        }

        // emit ERC1155Created(msg.sender, work);
        return address(work);
    }

    function getWorkByID(uint256 workID) public view returns (SPT) {
        return SPT(workIdToContract[workID]);
    }

    function getAuthorWorks(address author) public view returns (SPT[] memory) {
        return authorWorks[author];
    }

    function getWorkAuthors(
        uint256 workID
    ) public view returns (address[] memory) {
        return workAuthors[workID];
    }

    // function getWorkReadings(uint256 workID) public view returns (uint256) {
    //     return workAuthors[workID];
    // }

    /*
    mintERC1155 - mints a ERC1155 token with given parameters

    _index - index position in our tokens array - represents which ERC1155 you want to interact with
    _name - Case-sensitive. Name of the token (this maps to the ID you created when deploying the token)
    _amount - amount of tokens you wish to mint
    */
    // function mintERC1155(
    //     uint _index,
    //     string memory _name,
    //     uint256 amount
    // ) public {
    //     uint id = getIdByName(_index, _name);
    //     works[_index].mint(indexToOwner[_index], id, amount);
    //     emit ERC1155Minted(
    //         works[_index].owner(),
    //         address(works[_index]),
    //         amount
    //     );
    // }

    /*
    Helper functions below retrieve contract data given an ID or name and index in the tokens array.
    */
    // function getCountERC1155byIndex(
    //     uint256 _index,
    //     uint256 _id
    // ) public view returns (uint amount) {
    //     return works[_index].balanceOf(indexToOwner[_index], _id);
    // }

    // function getCountERC1155byName(
    //     uint256 _index,
    //     string calldata _name
    // ) public view returns (uint amount) {
    //     uint id = getIdByName(_index, _name);
    //     return works[_index].balanceOf(indexToOwner[_index], id);
    // }

    // function getIdByName(
    //     uint _index,
    //     string memory _name
    // ) public view returns (uint) {
    //     return works[_index].nameToId(_name);
    // }

    // function getNameById(
    //     uint _index,
    //     uint _id
    // ) public view returns (string memory) {
    //     return works[_index].idToName(_id);
    // }

    // function getERC1155byIndexAndId(
    //     uint _index,
    //     uint _id
    // )
    //     public
    //     view
    //     returns (
    //         address _contract,
    //         address _owner,
    //         string memory _uri,
    //         uint supply
    //     )
    // {
    //     ERC1155Token token = works[_index];
    //     return (
    //         address(token),
    //         token.owner(),
    //         token.uri(_id),
    //         token.balanceOf(indexToOwner[_index], _id)
    //     );
    // }

    function setLibrary(address libraryAddress) external {
        _libraryAddress = libraryAddress;
    }
}
