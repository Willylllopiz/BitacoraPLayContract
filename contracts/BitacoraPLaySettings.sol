pragma solidity ^0.6.2;

import "./SettingsBasic.sol";

contract BitacoraPlaySettings is SettingsBasic {
    event ReferredRangeConfigAdded(address indexed admin, uint8 _referredRangeId, uint _assetsDirect, uint _assetsSameNetwork, uint8 _qualifyingCycles, uint _bonusValue, uint _surplus, uint _remainderVehicleBonus);
    event ReferredRangeConfigDeleted(address indexed admin, uint8 _referredRangeId);
    event ReferredRangeConfigUpdated(address indexed admin, uint8 _referredRangeId, uint _assetsDirect, uint _assetsSameNetwork, uint8 _qualifyingCycles, uint _bonusValue, uint _surplus, uint _remainderVehicleBonus);

    // event CareerRangeConfigAdded(address indexed admin, uint8 _careerRangeId, uint _assetsDirect, uint _assetsSameNetwork, uint _bonusValue, uint _surplus);
    // event CareerRangeConfigDeleted(address indexed admin, uint8 _careerRangeId);
    // event CareerRangeConfigUpdated(address indexed admin, uint8 _referredRangeId, uint _assetsDirect, uint _assetsSameNetwork, uint _bonusValue, uint _surplus);

    struct ReferredRangeConfig {
        bool active;
        uint assetsDirect;
        uint assetsSameNetwork;
        uint8 qualifyingCycles;

        uint bonusValue;
        uint surplus;
        uint remainderVehicleBonus;
    }

    // struct CareerRangeConfig {
    //     bool active;
    //     uint assetsDirect;
    //     uint assetsSameNetwork;
    //     uint bonusValue;
    //     uint surplus;
    // }

 

    // struct ProsumerLevelConfig {     
    //     uint bonusValue;   
    //     uint surplus;     
        
    // }

    // struct CycleConfig {
    //     bool active;
    //     uint assetsDirect;
    //     uint amountToPay;
    //     uint promotionBonus;
    // }


    mapping(uint8 => ReferredRangeConfig) internal referredRangeConfig;
    // mapping(uint8 => CareerRangeConfig) internal careerRangeConfig;
    // mapping(uint8 => ProsumerLevelConfig) internal prosumerLevelConfig;
    // mapping(uint8 => mapping(uint8 => CycleConfig)) internal prosumerPerCycleConfig;
    //  mapping(uint8 => mapping(uint8 => uint)) viewsCycleConfig;

    uint8 public referredRangeCount;
    // uint8 public careerRangeCount;
    // uint8 public prosumerRangeCount;
    // uint8 public prosumerLevelCount;

    constructor(ITRC20 _depositTokenAddress) public {
        _initialize(msg.sender, _depositTokenAddress);
    }

    function _initialize(address _owner, ITRC20 _depositTokenAddress) private {
        _initializeSettingsBasic(_owner, _depositTokenAddress);
        referredRangeCount = 5;
        // careerRangeCount = 4;
        // prosumerRangeCount = 3;
        // prosumerLevelCount = 4;

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


        // careerRangeConfig [1] = CareerRangeConfig({active: true, assetsDirect: 30, assetsSameNetwork: 0, bonusValue: 750e18, surplus:0});
        // careerRangeConfig [2] = CareerRangeConfig({active: true, assetsDirect: 70, assetsSameNetwork: 0, bonusValue: 1750e18, surplus:0});
        // careerRangeConfig [3] = CareerRangeConfig({active: true, assetsDirect: 0, assetsSameNetwork: 1000, bonusValue: 1800e18, surplus:0});
        // careerRangeConfig [4] = CareerRangeConfig({active: true, assetsDirect: 0, assetsSameNetwork: 5000, bonusValue: 7200e18, surplus:0});



        // // Prosumer Guia, Cycle 1
        // prosumerPerCycleConfig[1][1] = CycleConfig({active: true, assetsDirect: 6, amountToPay:8e18, promotionBonus: 6.4e18});
        // // Prosumer Teacher, Cycles 1,2,3
        // prosumerPerCycleConfig[2][1] = CycleConfig({active: true, assetsDirect: 7, amountToPay:10e18, promotionBonus: 6.8e18});
        // prosumerPerCycleConfig[2][2] = CycleConfig({active: true, assetsDirect: 8, amountToPay:13e18, promotionBonus: 6.2e18});
        // prosumerPerCycleConfig[2][3] = CycleConfig({active: true, assetsDirect: 10, amountToPay:15e18, promotionBonus: 9e18});
        // // Prosumer Mentor, Cycles 1,2,3,4,5,6
        // prosumerPerCycleConfig[3][1] = CycleConfig({active: true, assetsDirect: 8, amountToPay:14e18, promotionBonus: 5.2e18});
        // prosumerPerCycleConfig[3][2] = CycleConfig({active: true, assetsDirect: 9, amountToPay:16e18, promotionBonus: 5.6e18});
        // prosumerPerCycleConfig[3][3] = CycleConfig({active: true, assetsDirect: 12, amountToPay:18e18, promotionBonus: 10.8e18});
        // prosumerPerCycleConfig[3][4] = CycleConfig({active: true, assetsDirect: 15, amountToPay:20e18, promotionBonus: 16e18});
        // prosumerPerCycleConfig[3][5] = CycleConfig({active: true, assetsDirect: 20, amountToPay:30e18, promotionBonus: 18e18});
        // prosumerPerCycleConfig[3][6] = CycleConfig({active: true, assetsDirect: 30, amountToPay:22e18, promotionBonus: 50e18});

        // // Prosumer Teacher BonusUp
        // prosumerLevelConfig[1].bonusValue = 640e18;        
        // prosumerLevelConfig[1].surplus = 0;
        // viewsCycleConfig[1][1] = 100;
        // // Prosumer Mentor BonusUp
        // prosumerLevelConfig[2].bonusValue = 7000e18;
        // prosumerLevelConfig[2].surplus = 720e18;
        // viewsCycleConfig[2][1] = 200;
        // viewsCycleConfig[2][2] = 300;
        // viewsCycleConfig[2][3] = 500;
        // // Prosumer Mentor Star BonusUp
        // prosumerLevelConfig[3].bonusValue = 50000e18;
        // prosumerLevelConfig[3].surplus = 1000e18;
        // viewsCycleConfig[3][4] = 200;
        // viewsCycleConfig[3][5] = 300;
        // // Prosumer Mentor Top BonusUp
        // prosumerLevelConfig[4].bonusValue = 100000e18;
        // prosumerLevelConfig[4].surplus = 10000e18;
        // viewsCycleConfig[4][6] = 500;

    }

// Start Region Referred

    function addReferredRangeConfig(uint _assetsDirect, uint _assetsSameNetwork, uint8 _qualifyingCycles, uint _bonusValue, uint _surplus, uint _remainderVehicleBonus) external restricted {
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

    function deleteReferredRangeConfig(uint8 _referredRangeId) external restricted {
        require(0 < _referredRangeId && _referredRangeId <= referredRangeCount, "BitacoraPlaySettings: Referred Range does not exist");
        require(referredRangeConfig[_referredRangeId].active, "BitacoraPlaySettings: Referred Range does not exist");
        referredRangeConfig[_referredRangeId].active = false;
        emit ReferredRangeConfigDeleted(msg.sender, _referredRangeId);
    }

    function updateReferredRangeConfig(uint8 _referredRangeId, uint _assetsDirect, uint _assetsSameNetwork, uint8 _qualifyingCycles, uint _bonusValue, uint _surplus, uint _remainderVehicleBonus) external restricted {
        require(0 < _referredRangeId && _referredRangeId <= referredRangeCount, "MoneyBoxSettings: Referred Range does not exist");
        referredRangeConfig[_referredRangeId].assetsDirect = _assetsDirect;
        referredRangeConfig[_referredRangeId].assetsSameNetwork = _assetsSameNetwork;
        referredRangeConfig[_referredRangeId].qualifyingCycles = _qualifyingCycles;
        referredRangeConfig[_referredRangeId].surplus = _surplus;
        referredRangeConfig[_referredRangeId].remainderVehicleBonus = _remainderVehicleBonus;
        emit ReferredRangeConfigUpdated(msg.sender, _referredRangeId, _assetsDirect, _assetsSameNetwork, _qualifyingCycles, _bonusValue, _surplus, _remainderVehicleBonus);
    }    

    function getReferredConfigInfo(uint8 _referredRangeId) public view returns(uint, uint, uint8, uint, uint, uint) {
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

// End Region Referred


// Start Region Career
   
    // function addCareerRangeConfig(uint _assetsDirect, uint _assetsSameNetwork, uint _bonusValue, uint _surplus) external restricted {
    //     careerRangeCount++;
    //     careerRangeConfig[careerRangeCount] = CareerRangeConfig({
    //         active: true,
    //         assetsDirect: _assetsDirect,
    //         assetsSameNetwork: _assetsSameNetwork,
    //         bonusValue: _bonusValue,
    //         surplus:_surplus
    //     });
    //     emit CareerRangeConfigAdded(msg.sender, referredRangeCount, _assetsDirect, _assetsSameNetwork, _bonusValue, _surplus);
    // }

    // function deleteCareerRangeConfig(uint8 _careerRangeId) external restricted {
    //     require(0 < _careerRangeId && _careerRangeId <= careerRangeCount, "BitacoraPlaySettings: CareerRange does not exist");
    //     require(careerRangeConfig[_careerRangeId].active, "BitacoraPlaySettings: Career Range does not exist");
    //     careerRangeConfig[_careerRangeId].active = false;
    //     emit CareerRangeConfigDeleted(msg.sender, _careerRangeId);
    // }    

    // function updateCareerRangeConfig(uint8 _careerRangeId, uint _assetsDirect, uint _assetsSameNetwork, uint _bonusValue, uint _surplus) external restricted {
    //     require(0 < _careerRangeId && _careerRangeId <= referredRangeCount, "MoneyBoxSettings: Category does not exist");
    //     referredRangeConfig[_careerRangeId].assetsDirect = _assetsDirect;
    //     referredRangeConfig[_careerRangeId].assetsSameNetwork = _assetsSameNetwork;
    //     referredRangeConfig[_careerRangeId].surplus = _surplus;
    //     emit CareerRangeConfigUpdated(msg.sender, _careerRangeId, _assetsDirect, _assetsSameNetwork, _bonusValue, _surplus);
    // }

    // function getCareerConfigInfo(uint8 _careerRangeId) public view returns(uint, uint, uint, uint) {
    //     require(0 < _careerRangeId && _careerRangeId <= referredRangeCount, "BitacoraPlaySettings: Career Config does not exist");
    //     return (
    //         careerRangeConfig[_careerRangeId].assetsDirect,
    //         careerRangeConfig[_careerRangeId].assetsSameNetwork,
    //         careerRangeConfig[_careerRangeId].bonusValue,
    //         careerRangeConfig[_careerRangeId].surplus
    //     );
    // }

// End Region Career

// Start Region Prosumer

    // function getProsumerConfigInfo(uint8 _prosumerRangeId) public view returns(uint, uint, uint) {
    //     require(0 < _prosumerRangeId && _prosumerRangeId <= referredRangeCount, "BitacoraPlaySettings: Prosumer Config does not exist");
    //     return ( 
    //         prosumerRangeConfig[_prosumerRangeId].assetsDirect,
    //         prosumerRangeConfig[_prosumerRangeId].bonusValue,
    //         prosumerRangeConfig[_prosumerRangeId].surplus
    //     );
    // }

    // function getProsumerPerCycleConfig(uint8 _prosumerLevel, uint8 _cycle) public view returns(uint, uint, uint){
    //     require(0 < _prosumerLevel, "BitacoraPlaySettings: Prosumer Config does not exist");//TODO:revisar estas comprobaciones
    //     return(
    //         prosumerPerCycleConfig[_prosumerLevel][_cycle].assetsDirect,
    //         prosumerPerCycleConfig[_prosumerLevel][_cycle].amountToPay,
    //         prosumerPerCycleConfig[_prosumerLevel][_cycle].promotionBonus
    //     );
    // }

    // function getProsumerLevelConfig(uint8 _prosumerLevel) public view returns(uint, uint){
    //     require(0 < _prosumerLevel, "BitacoraPlaySettings: Prosumer Config does not exist");//TODO:revisar estas comprobaciones ojo
    //     return(
    //         prosumerLevelConfig[_prosumerLevel].bonusValue,
    //         prosumerLevelConfig[_prosumerLevel].surplus
    //     );
    // }

    // function getViewsCycleConfig(uint8 _prosumerLevel, uint8 _cycle) public view returns(uint){
    //     require(0 < _prosumerLevel, "BitacoraPlaySettings: Prosumer Config does not exist");//TODO:revisar estas comprobaciones ojo
    //     return viewsCycleConfig[_prosumerLevel][_cycle];
    // }
// End Region Prosumer
}
