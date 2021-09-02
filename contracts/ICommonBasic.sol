// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

interface ICommonBasic {
    event ExtractLostTokens(address indexed _admin, address indexed _token, uint _amount);

    function withdrawLostTokens(address tokenAddress) external returns(bool);
}
