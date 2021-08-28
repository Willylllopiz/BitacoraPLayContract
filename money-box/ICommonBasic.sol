// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

interface ICommonBasic {
    event AdminAdded(address indexed _emitterAdmin, address indexed _addedAdmin);
    event AdminDeleted(address indexed _emitterAdmin, address indexed _deletedAdmin);
    event AdminExtractLostTokens(address indexed _admin, address indexed _token, uint _amount);

    function withdrawLostTokens(address tokenAddress) external returns(bool);
    function addAdmin(address user) external returns(bool);
    function deleteAdmin(address user) external returns(bool);
    function getAdmins() external view returns(address[] memory);
    function isAdmin(address user) external view returns(bool);
}
