// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./ICommonBasic.sol";

interface ISettingsBasic is ICommonBasic {
    event AdminAdded(address indexed _emitterAdmin, address indexed _addedAdmin, uint8 _adminId);
    event AdminActivated(address indexed _emitterAdmin, address indexed _addedAdmin, uint8 _adminId);
    event AdminDisabled(address indexed _emitterAdmin, address indexed _deletedAdmin, uint8 _adminId);
    
    function addAdmin(address user) external returns(bool);
    function deleteAdmin(address user) external returns(bool);
    function getAllAdmins() external view returns(address[] memory);
    function getActiveAdmins() external view returns(address[] memory);
    function isAdmin(address user) external view returns(bool);
}
