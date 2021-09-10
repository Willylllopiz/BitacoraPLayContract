// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

interface ICommonBasic {
    function withdrawLostTokens(address tokenAddress) external returns(bool);
}
