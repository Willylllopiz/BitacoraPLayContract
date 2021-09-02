// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./ISettingsBasic.sol";

interface IMoneyBoxSettings is ISettingsBasic {
    event CategoryConfigAdded(address indexed admin, string key, uint16 percentage, uint16 countDays, uint minDeposit, uint maxDeposit);
    event CategoryConfigDeleted(address indexed admin, string key);
    event CategoryConfigUpdated(address indexed admin, string key, uint16 percentage, uint16 countDays, uint minDeposit, uint maxDeposit);
    
    function addCategory(bytes4 name, uint16 percentage, uint16 countDays, uint minDeposit, uint maxDeposit) external;
    function deleteCategory(uint8 categoryId) external;
    function updateCategory(uint8 categoryId, bytes4 name, uint16 percentage, uint16 countDays, uint minDeposit, uint maxDeposit) external;
    function getCategoryInfo(uint8 categoryId) external view returns(bytes4, uint16, uint16, uint, uint);
}
