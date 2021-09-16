pragma solidity ^0.6.2;

// SPDX-License-Identifier: MIT

interface IBitacoraPlay {
    function isUserExists(address user) external view returns (bool);
    function isActivatedMembership(address _user) external view returns(bool);
    function getReferrer(address _userAddress) external view returns(address);
    function getAccumulatedDirectToSeeCourse(address _userAddress) external view returns(uint);
    // function setExternalPendingBonus(address _user, uint _moneyBox, uint _adminBonus, uint _himself, uint8 _level, uint8 _plan) external ;
}