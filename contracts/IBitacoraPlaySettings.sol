// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./ISettingsBasic.sol";

interface IBitacoraPlaySettings is ISettingsBasic {    
    function addReferredRangeConfig(uint _assetsDirect, uint _assetsSameNetwork, uint8 _qualifyingCycles, uint _bonusValue, uint _surplus, uint _remainderVehicleBonus)  external;
    function deleteReferredRangeConfig(uint8 _referredRangeId) external;
    function updateReferredRangeConfig(uint8 _referredRangeId, uint _assetsDirect, uint _assetsSameNetwork, uint8 _qualifyingCycles, uint _bonusValue, uint _surplus, uint _remainderVehicleBonus) external;
    function getReferredConfigInfo(uint8 _referredRangeId) external view returns(uint, uint, uint8, uint, uint, uint);

    // function addCareerRangeConfig(uint _assetsDirect, uint _assetsSameNetwork, uint _bonusValue, uint _surplus)  external;    
    // function deleteCareerRangeConfig(uint8 _careerRangeId) external;
    // function updateCareerRangeConfig(uint8 _careerRangeId, uint _assetsDirect, uint _assetsSameNetwork, uint _bonusValue, uint _surplus) external;
    // function getCareerConfigInfo(uint8 _careerRangeId) external view returns(uint, uint, uint, uint);

    // function getProsumerConfigInfo(uint8 _prosumerRangeId) external view returns(uint, uint, uint);
    // function getProsumerPerCycleConfig(uint8 _prosumerLevel, uint8 _cycle) external view returns(uint, uint, uint);
    // function getProsumerLevelConfig(uint8 _prosumerLevel) external view returns(uint, uint);
    // function getViewsCycleConfig(uint8 _prosumerLevel, uint8 _cycle) external view returns(uint);

}
