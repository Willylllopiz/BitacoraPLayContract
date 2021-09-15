// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./ISettingsBasic.sol";
import "./ITRC20.sol";

interface IMoneyBoxSettings is ISettingsBasic {
    function initialize(ITRC20 _depositTokenAddress) external;
    function addCategory(bytes4 name, uint16 percentage, uint16 countDays, uint minDeposit, uint maxDeposit) external;
    function deleteCategory(uint8 categoryId) external;
    function updateCategory(uint8 categoryId, bytes4 name, uint16 percentage, uint16 countDays, uint minDeposit, uint maxDeposit) external;
    function getCountCategories() external view returns(uint8);
    function getCategoryInfo(uint8 categoryId) external view returns(bytes4, uint16, uint16, uint, uint, bool);
    function addBonusDistribution(uint64 accumulateNecessary, uint amount) external;
    function changeBonusDistribution(uint8 bonusDistributionId, uint64 accumulateNecessary, uint amount) external;
    function changeRegisterSettings(uint newRegisterPrice, uint newAmountForBonus) external;
    function getLogicSettings() external view returns(uint, uint, uint8);
    function getBonusDistribution(uint8 id) external view returns(uint64, uint);
    function getBonusesCount() external view returns(uint8);
}
