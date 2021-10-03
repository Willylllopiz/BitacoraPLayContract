// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./ICommonBasic.sol";

interface ISettingsBasic is ICommonBasic {
    function addAdmin(address user) external returns(bool);
    function deleteAdmin(address user) external returns(bool);
    function getAllAdmins() external view returns(address[] memory);
    function getActiveAdmins() external view returns(address[] memory);
    function isAdmin(address user) external view returns(bool);
    function getCommonSettings() external view returns(uint8, uint8, uint, uint);
    function setCommonSettings(uint8 minAllowedAdmins, uint8 maxAllowedAdmins, uint maxAmountToWithdraw, uint minAmountToWithdraw) external;
}
