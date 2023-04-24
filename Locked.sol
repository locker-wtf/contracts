// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./ILockedNFT.sol";

contract Locked is Ownable {
    ILockedNFT LOCKED_NFT;
    uint256 WITHDRAW_PERIOD = 604800; //86400*7
    uint256 FEE = 5; //0.05%

    bool init;
    address feeAddr;
    mapping(uint256 => uint256) withdrawConfirmTime;
    mapping(uint256 => uint8) withdrawStatus;

    event DepositEvt(
        address owner,
        uint256 tokenId,
        address token,
        uint256 amount,
        uint256 time,
        bytes32 data
    );
    event WithdrawApplyEvt(address owner, uint256 _tokenId, uint256 time);
    event WithdrawEvt(address owner, uint256 _tokenId, uint256 time);

    function setLockedNFT(ILockedNFT _addr) public onlyOwner {
        require(init == false, "contract inited");
        LOCKED_NFT = _addr;
        init = true;
    }

    function setFeeAddr(address _addr) public onlyOwner {
        feeAddr = _addr;
    }

    function deposit(
        IERC20 _token,
        uint256 _amount,
        uint256 _time,
        bytes32 _data
    ) public {
        require(_amount > 0, "Please enter the locked amount");
        require(_time > block.timestamp, "Please select a future time");

        uint256 _beforeTokenBalance = _token.balanceOf(address(this));
        bool _transRes = _token.transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        require(_transRes, "transfer fail");
        uint256 _afterTokenBalance = _token.balanceOf(address(this));
        require(
            _beforeTokenBalance + _amount == _afterTokenBalance,
            "There is a problem with the token contract"
        );

        // fee
        uint256 feeAmount = (_amount * 10000) / FEE;
        uint256 realAmount = _amount - feeAmount;
        if (feeAmount > 0) {
            _token.transfer(feeAddr, feeAmount);
        }

        uint256 _tokenId = LOCKED_NFT.getSupply();

        LOCKED_NFT.mint(
            msg.sender,
            _tokenId + 1,
            address(_token),
            realAmount,
            _time,
            _data
        );

        emit DepositEvt(
            msg.sender,
            _tokenId,
            address(_token),
            realAmount,
            _time,
            _data
        );
    }

    function applyWithdraw(uint256 _tokenId) public {
        address nftOwner = LOCKED_NFT.ownerOf(_tokenId);
        require(msg.sender == nftOwner, "Operation without permission");

        require(withdrawConfirmTime[_tokenId] == 0, "Do not apply again");

        ILockedNFT.Metadata memory _metadata = LOCKED_NFT.metadata(_tokenId);
        uint256 confirmTime = block.timestamp + WITHDRAW_PERIOD;
        require(confirmTime > _metadata.time, "Not yet the withdrawal time");

        withdrawConfirmTime[_tokenId] = confirmTime;

        emit WithdrawApplyEvt(msg.sender, _tokenId, block.timestamp);
    }

    function withdraw(uint256 _tokenId) public {
        address nftOwner = LOCKED_NFT.ownerOf(_tokenId);
        require(msg.sender == nftOwner, "Operation without permission");

        require(
            withdrawConfirmTime[_tokenId] != 0 &&
                withdrawConfirmTime[_tokenId] < block.timestamp,
            "Not yet the withdrawal time"
        );

        require(withdrawStatus[_tokenId] == 0, "Has been withdrawn");
        withdrawStatus[_tokenId] = 1;

        ILockedNFT.Metadata memory _metadata = LOCKED_NFT.metadata(_tokenId);

        LOCKED_NFT.burn(_tokenId);

        IERC20(_metadata.token).transfer(nftOwner, _metadata.amount);

        emit WithdrawEvt(msg.sender, _tokenId, block.timestamp);
    }
}
