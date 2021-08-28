// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./ICommonBasic.sol";
import "./ITRC20.sol";
import "./SafeTRC20.sol";

contract CommonBasic is ICommonBasic {
    using SafeTRC20 for ITRC20;

    address[] adminsArray;
    ITRC20 public depositToken;

    modifier restricted() {
        require(_adminIndex(msg.sender) < adminsArray.length, "CommonBasic: only admins");
        _;
    }

    function withdrawLostTokens(address tokenAddress) external override(ICommonBasic) restricted returns(bool) {
        address(uint160(msg.sender)).transfer(address(this).balance);

        require(tokenAddress != address(depositToken), "CommonBasic: Cannot withdraw deposit token");
        uint amount;
        if (tokenAddress == address(0)) {
            amount = address(this).balance;
            address(uint160(msg.sender)).transfer(address(this).balance);
        } else {
            amount = ITRC20(tokenAddress).balanceOf(address(this));
            ITRC20(tokenAddress).transfer(msg.sender, ITRC20(tokenAddress).balanceOf(address(this)));
        }

        emit AdminExtractLostTokens(msg.sender, tokenAddress, amount);
        return true;
    }

    function addAdmin(address user) external override(ICommonBasic) restricted returns(bool) {
        require(_adminIndex(user) == adminsArray.length, 'CommonBasic: The address is already admin');
        adminsArray.push(user);
        emit AdminAdded(msg.sender, user);
        return true;
    }

    function deleteAdmin(address user) external override(ICommonBasic) restricted returns(bool) {
        uint index = _adminIndex(user);
        require(index < adminsArray.length, "CommonBasic: The address isn't admin");
        require(adminsArray.length > 1, 'CommonBasic: At least one admin is required');
        adminsArray[index] = adminsArray[adminsArray.length - 1];
        adminsArray.pop();
        emit AdminDeleted(msg.sender, user);
        return true;
    }

    function getAdmins() external override(ICommonBasic) view returns(address[] memory) {
        return adminsArray;
    }

    function isAdmin(address user) external override(ICommonBasic) view returns(bool) {
        return _adminIndex(user) < adminsArray.length;
    }

    function _initializeCommonBasic(address _owner, ITRC20 _depositTokenAddress) internal {
        adminsArray = [_owner];
        depositToken = _depositTokenAddress;
    }

    function _adminIndex(address user) internal view returns(uint) {
        for (uint i = 0; i < adminsArray.length; i++) {
            if(adminsArray[i] == user)
                return i;
        }
        return adminsArray.length;
    }
}
