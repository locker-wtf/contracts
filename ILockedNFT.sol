// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILockedNFT {
    struct Metadata {
        address token;
        uint256 amount;
        uint256 time;
        bytes32 data;
    }

    function mint(
        address _sender,
        uint256 _tokenId,
        address _token,
        uint256 _amount,
        uint256 _time,
        bytes32 _data
    ) external;

    function burn(uint256 _tokenId) external;

    function getSupply() external view returns (uint256);

    function metadata(uint256 _tokenId)
        external
        view
        returns (Metadata memory _metadata);

    function ownerOf(uint256 _tokenId) external returns (address _owner);
}
