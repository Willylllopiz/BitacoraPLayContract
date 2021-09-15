pragma solidity ^0.6.2;
// SPDX-License-Identifier: MIT

interface IMoneyBox {
    function addToBalance( address _user,uint _amount) external returns(bool);
}
