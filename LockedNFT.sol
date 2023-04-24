// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract LockedNFT is ERC721URIStorage, Ownable {
    constructor() ERC721("Locked", "L") {}

    uint256 supply = 0;

    struct Metadata {
        address token;
        uint256 amount;
        uint256 time;
        bytes32 data;
    }

    mapping(uint256 => Metadata) table;

    function getSupply() external view returns (uint256) {
        return supply;
    }

    function mint(
        address _sender,
        uint256 _tokenId,
        address _token,
        uint256 _amount,
        uint256 _time,
        bytes32 _data
    ) public onlyOwner {
        require(supply + 1 == _tokenId, "tokenId failure");
        supply = _tokenId;
        table[_tokenId] = Metadata(_token, _amount, _time, _data);
        _mint(_sender, _tokenId);
    }

    function metadata(uint256 _tokenId)
        public
        view
        returns (Metadata memory _metadata)
    {
        require(_tokenId <= supply, "tokenId is invalid");
        _metadata = table[_tokenId];
    }

    function burn(uint256 _tokenId) public {
        require(table[_tokenId].amount > 0, "does not exist");
        table[_tokenId].amount = 0;
        _burn(_tokenId);
    }
}
