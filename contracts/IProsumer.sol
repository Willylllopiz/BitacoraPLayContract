pragma solidity ^0.6.2;

// SPDX-License-Identifier: MIT

interface IProsumer {
    // function setAccumulatedDirectToSeeCourse(address _user) external;
    function getTransferBalanceByCourse(uint _course, uint _accumulatedDirectToSeeCourse) external view returns(uint);
    function buyCourse(uint _course, address _user) external returns(address, uint, uint, uint, uint, uint8, uint8);
}