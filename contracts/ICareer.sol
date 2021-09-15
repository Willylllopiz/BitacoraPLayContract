pragma solidity ^0.6.2;

// SPDX-License-Identifier: MIT

interface ICareer {
    function isActive(address _userAddress) external view returns(bool);
}