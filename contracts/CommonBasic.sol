// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./ICommonBasic.sol";
import "./ITRC20.sol";
import "./SafeTRC20.sol";

abstract contract CommonBasic is ICommonBasic {
    ITRC20 depositToken;
    using SafeTRC20 for ITRC20;

    modifier restrictedWithdrawLostTokens() virtual {_;}

    function withdrawLostTokens(address tokenAddress) external override restrictedWithdrawLostTokens returns(bool) {
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
}
