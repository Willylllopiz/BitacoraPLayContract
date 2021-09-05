// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./ISettingsBasic.sol";

interface IBitacoraPlaySettings is ISettingsBasic {
    event ReferredRangeConfigAdded(address indexed admin, uint8 _referredRangeId, uint _assetsDirect, uint _assetsSameNetwork, uint8 _qualifyingCycles, uint _bonusValue, uint _surplus, uint _remainderVehicleBonus);
    event CareerRangeConfigAdded(address indexed admin, uint8 _careerRangeId, uint _assetsDirect, uint _assetsSameNetwork, uint _bonusValue, uint _surplus);
    event ReferredRangeConfigDeleted(address indexed admin, uint8 _referredRangeId);
    event CareerRangeConfigDeleted(address indexed admin, uint8 _referredRangeId);
    event ReferredRangeConfigUpdated(address indexed admin, uint8 _referredRangeId, uint _assetsDirect, uint _assetsSameNetwork, uint8 _qualifyingCycles, uint _bonusValue, uint _surplus, uint _remainderVehicleBonus);
    event CareerdRangeConfigUpdated(address indexed admin, uint8 _careerRangeId, uint _assetsDirect, uint _assetsSameNetwork, uint _bonusValue, uint _surplus);

    function addReferredRangeConfig(uint _assetsDirect, uint _assetsSameNetwork, uint8 _qualifyingCycles, uint _bonusValue, uint _surplus, uint _remainderVehicleBonus)  external;
    function addCareerRangeConfig(uint _assetsDirect, uint _assetsSameNetwork, uint _bonusValue, uint _surplus)  external;
    function deleteReferredRangeConfig(uint8 _referredRangeId) external;
    function deleteCareerRangeConfig(uint8 _careerRangeId) external;
    function updateCareerRangeConfig(uint8 _careerRangeId, uint _assetsDirect, uint _assetsSameNetwork, uint _bonusValue, uint _surplus) external;
    function updateReferredRangeConfig(uint8 _referredRangeId, uint _assetsDirect, uint _assetsSameNetwork, uint8 _qualifyingCycles, uint _bonusValue, uint _surplus, uint _remainderVehicleBonus) external;
    function getReferredConfigInfo(uint8 _referredRangeId) external view returns(uint, uint, uint8, uint, uint, uint);
    function getCareerConfigInfo(uint8 _careerRangeId) external view returns(uint, uint, uint, uint);
}
