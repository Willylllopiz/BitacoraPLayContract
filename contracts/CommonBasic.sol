// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./ITRC20.sol";

abstract contract CommonBasic {
    event ExtractLostTokens(address indexed _admin, address indexed _token, uint _amount);

    ITRC20 depositToken;
    address public _owner;
    bool public _locked;

    modifier onlyOwner() {
        require(_owner == msg.sender, "[CommonBasic]: Only owner");
        _;
    }

    modifier onlyUnlocked() {
        require(!_locked || msg.sender == _owner);
        _;
    }

    modifier restrictedWithdrawLostTokens() virtual {_;}

    function withdrawLostTokens(address tokenAddress) external restrictedWithdrawLostTokens returns(bool) {
        require(tokenAddress != address(depositToken), "CommonBasic: Cannot withdraw deposit token");
        if (tokenAddress == address(0)) {
            emit ExtractLostTokens(msg.sender, tokenAddress, address(this).balance);
            address(uint160(msg.sender)).transfer(address(this).balance);
        } else {
            emit ExtractLostTokens(msg.sender, tokenAddress, ITRC20(tokenAddress).balanceOf(address(this)));
            ITRC20(tokenAddress).transfer(msg.sender, ITRC20(tokenAddress).balanceOf(address(this)));
        }
        return true;
    }

    function changeLock() external onlyOwner {
        _locked = !_locked;
    }
}
