pragma solidity ^0.6.2;

import "./SettingsBasic.sol";
import "./IBitacoraPlaySettings.sol";

contract BitacoraPlaySettings is SettingsBasic, IBitacoraPlaySettings {
    event ReferredRangeConfigAdded(address indexed admin, uint8 _referredRangeId, uint _assetsDirect, uint _assetsSameNetwork, uint8 _qualifyingCycles, uint _bonusValue, uint _surplus, uint _remainderVehicleBonus);
    event CareerRangeConfigAdded(address indexed admin, uint8 _careerRangeId, uint _assetsDirect, uint _assetsSameNetwork, uint _bonusValue, uint _surplus);
    event ReferredRangeConfigDeleted(address indexed admin, uint8 _referredRangeId);
    event CareerRangeConfigDeleted(address indexed admin, uint8 _careerRangeId);
    event ReferredRangeConfigUpdated(address indexed admin, uint8 _referredRangeId, uint _assetsDirect, uint _assetsSameNetwork, uint8 _qualifyingCycles, uint _bonusValue, uint _surplus, uint _remainderVehicleBonus);
    event CareerRangeConfigUpdated(address indexed admin, uint8 _referredRangeId, uint _assetsDirect, uint _assetsSameNetwork, uint _bonusValue, uint _surplus);

    struct ReferredRangeConfig {
        bool active;
        uint assetsDirect;
        uint assetsSameNetwork;
        uint8 qualifyingCycles;

        uint bonusValue;
        uint surplus;
        uint remainderVehicleBonus;
    }

    struct CareerRangeConfig {
        bool active;
        uint assetsDirect;
        uint assetsSameNetwork;
        uint bonusValue;
        uint surplus;
    }


    mapping(uint8 => ReferredRangeConfig) internal referredRangeConfig;
    mapping(uint8 => CareerRangeConfig) internal careerRangeConfig;

    uint8 referredRangeCount;
    uint8 careerRangeCount;

    constructor(ITRC20 _depositTokenAddress) public {
        _initialize(msg.sender, _depositTokenAddress);
    }

    function _initialize(address _owner, ITRC20 _depositTokenAddress) private {
        _initializeSettingsBasic(_owner, _depositTokenAddress);
        referredRangeCount = 5;
        careerRangeCount = 4;

        // Rookie Bonus Configuration
        referredRangeConfig[1] = ReferredRangeConfig({
            active: true,
            assetsDirect: 0,
            assetsSameNetwork: 0,
            qualifyingCycles: 0,
            bonusValue: 0e18,
            surplus: 0e18,
            remainderVehicleBonus: 0e18
        });
        // // Junior Bonus Configuration
        referredRangeConfig [2] = ReferredRangeConfig({
            active: true,
            assetsDirect: 30,
            assetsSameNetwork: 3000,
            qualifyingCycles: 1,
            bonusValue: 500e18,
            surplus: 40e18, // TODO: en el documento dice que sobran 50 y son 40 revisar esto
            remainderVehicleBonus: 540e18
        });
        // Leader Bonus Configuration
        referredRangeConfig[3] = ReferredRangeConfig({
            active: true,
            assetsDirect: 100,
            assetsSameNetwork: 7000,
            qualifyingCycles: 2,
            bonusValue: 1800e18,
            surplus: 0e18,
            remainderVehicleBonus: 3240e18
        });
        // Guru Bonus Configuration
        referredRangeConfig[4] = ReferredRangeConfig({
            active: true,
            assetsDirect: 300,
            assetsSameNetwork: 20000,
            qualifyingCycles: 2,
            bonusValue: 4500e18,
            surplus: 0e18,
            remainderVehicleBonus: 9900e18
        });
        // GuruVehicle Bonus Configuration
        referredRangeConfig[5] = ReferredRangeConfig({
            active: true,
            assetsDirect: 300,
            assetsSameNetwork: 20000,
            qualifyingCycles: 2,
            bonusValue: 0e18,
            surplus: 0e18,
            remainderVehicleBonus: 14400e18
        });
        careerRangeConfig [1] = CareerRangeConfig({active: true, assetsDirect: 30, assetsSameNetwork: 0, bonusValue: 750e18, surplus:0});
        careerRangeConfig [2] = CareerRangeConfig({active: true, assetsDirect: 70, assetsSameNetwork: 0, bonusValue: 1750e18, surplus:0});
        careerRangeConfig [3] = CareerRangeConfig({active: true, assetsDirect: 0, assetsSameNetwork: 1000, bonusValue: 1800e18, surplus:0});
        careerRangeConfig [4] = CareerRangeConfig({active: true, assetsDirect: 0, assetsSameNetwork: 5000, bonusValue: 7200e18, surplus:0});
    }

    function addReferredRangeConfig(uint _assetsDirect, uint _assetsSameNetwork, uint8 _qualifyingCycles, uint _bonusValue, uint _surplus, uint _remainderVehicleBonus) override(IBitacoraPlaySettings) external restricted {
        referredRangeCount++;
        referredRangeConfig[referredRangeCount] = ReferredRangeConfig({
            active: true,
            assetsDirect: _assetsDirect,
            assetsSameNetwork: _assetsSameNetwork,
            qualifyingCycles: _qualifyingCycles,
            surplus: _surplus,
            bonusValue: _bonusValue,      
            remainderVehicleBonus: _remainderVehicleBonus
        });
        emit ReferredRangeConfigAdded(msg.sender, referredRangeCount, _assetsDirect, _assetsSameNetwork, _qualifyingCycles, _bonusValue, _surplus, _remainderVehicleBonus);
    }

    function addCareerRangeConfig(uint _assetsDirect, uint _assetsSameNetwork, uint _bonusValue, uint _surplus) override(IBitacoraPlaySettings) external restricted {
        careerRangeCount++;
        careerRangeConfig[careerRangeCount] = CareerRangeConfig({
            active: true,
            assetsDirect: _assetsDirect,
            assetsSameNetwork: _assetsSameNetwork,
            bonusValue: _bonusValue,
            surplus:_surplus
        });
        emit CareerRangeConfigAdded(msg.sender, referredRangeCount, _assetsDirect, _assetsSameNetwork, _bonusValue, _surplus);
    }

    function deleteReferredRangeConfig(uint8 _referredRangeId) override(IBitacoraPlaySettings) external restricted {
        require(0 < _referredRangeId && _referredRangeId <= referredRangeCount, "BitacoraPlaySettings: Referred Range does not exist");
        require(referredRangeConfig[_referredRangeId].active, "BitacoraPlaySettings: Referred Range does not exist");
        referredRangeConfig[_referredRangeId].active = false;
        emit ReferredRangeConfigDeleted(msg.sender, _referredRangeId);
    }

    function deleteCareerRangeConfig(uint8 _careerRangeId) override(IBitacoraPlaySettings) external restricted {
        require(0 < _careerRangeId && _careerRangeId <= careerRangeCount, "BitacoraPlaySettings: CareerRange does not exist");
        require(careerRangeConfig[_careerRangeId].active, "BitacoraPlaySettings: Career Range does not exist");
        careerRangeConfig[_careerRangeId].active = false;
        emit CareerRangeConfigDeleted(msg.sender, _careerRangeId);
    }

    function updateReferredRangeConfig(uint8 _referredRangeId, uint _assetsDirect, uint _assetsSameNetwork, uint8 _qualifyingCycles, uint _bonusValue, uint _surplus, uint _remainderVehicleBonus) override(IBitacoraPlaySettings) external restricted {
        require(0 < _referredRangeId && _referredRangeId <= referredRangeCount, "MoneyBoxSettings: Referred Range does not exist");
        referredRangeConfig[_referredRangeId].assetsDirect = _assetsDirect;
        referredRangeConfig[_referredRangeId].assetsSameNetwork = _assetsSameNetwork;
        referredRangeConfig[_referredRangeId].qualifyingCycles = _qualifyingCycles;
        referredRangeConfig[_referredRangeId].surplus = _surplus;
        referredRangeConfig[_referredRangeId].remainderVehicleBonus = _remainderVehicleBonus;
        emit ReferredRangeConfigUpdated(msg.sender, _referredRangeId, _assetsDirect, _assetsSameNetwork, _qualifyingCycles, _bonusValue, _surplus, _remainderVehicleBonus);
    }

    function updateCareerRangeConfig(uint8 _careerRangeId, uint _assetsDirect, uint _assetsSameNetwork, uint _bonusValue, uint _surplus) override(IBitacoraPlaySettings) external restricted {
        require(0 < _careerRangeId && _careerRangeId <= referredRangeCount, "MoneyBoxSettings: Category does not exist");
        referredRangeConfig[_careerRangeId].assetsDirect = _assetsDirect;
        referredRangeConfig[_careerRangeId].assetsSameNetwork = _assetsSameNetwork;
        referredRangeConfig[_careerRangeId].surplus = _surplus;
        emit CareerRangeConfigUpdated(msg.sender, _careerRangeId, _assetsDirect, _assetsSameNetwork, _bonusValue, _surplus);
    }

    function getReferredConfigInfo(uint8 _referredRangeId) override(IBitacoraPlaySettings) public view returns(uint, uint, uint8, uint, uint, uint) {
        require(0 < _referredRangeId && _referredRangeId <= referredRangeCount, "BitacoraPlaySettings: Referred Config does not exist");
        return (
            referredRangeConfig[_referredRangeId].assetsDirect,
            referredRangeConfig[_referredRangeId].assetsSameNetwork,
            referredRangeConfig[_referredRangeId].qualifyingCycles,
            referredRangeConfig[_referredRangeId].bonusValue,
            referredRangeConfig[_referredRangeId].surplus,
            referredRangeConfig[_referredRangeId].remainderVehicleBonus
        );
    }

    function getCareerConfigInfo(uint8 _careerRangeId) override(IBitacoraPlaySettings) public view returns(uint, uint, uint, uint) {
        require(0 < _careerRangeId && _careerRangeId <= referredRangeCount, "BitacoraPlaySettings: Career Config does not exist");
        return (
            careerRangeConfig[_careerRangeId].assetsDirect,
            careerRangeConfig[_careerRangeId].assetsSameNetwork,
            careerRangeConfig[_careerRangeId].bonusValue,
            careerRangeConfig[_careerRangeId].surplus
        );
    }
}
