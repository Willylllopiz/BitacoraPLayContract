pragma solidity ^0.6.2;
// SPDX-License-Identifier: MIT

import "./BitacoraPlayBasic.sol";
import "./BitacoraPlay.sol";
import "./Career.sol";
import "./SettingsBasic.sol";

contract Prosumer is SettingsBasic{
    event Prosumer_CompletedBonusEvent(address indexed _user, uint _userId, uint8 indexed _range, uint8 indexed plan);
    event Prosumer_BonusAvailableToCollectEvent(address indexed _user, uint _userId, uint8 indexed _range, uint8 indexed plan);
    event Prosumer_AvailableBalanceForMoneyBox(address indexed _user, uint _amounnt);
    event Prosumer_AvailableAdministrativeBalance(uint _amounnt); 

    struct User {
        bool isProsumer;
        uint accumulatedDirectToSeeCourse;
        uint8 prosumerLevel;
        uint8 prosumerBonusRange;
        uint accumulatedDirectPlanProsumer;
    }

    struct Course {
        uint id;
        uint8 cycle;
        address prosumerAuthor;
    }

    struct PendingBonus {
        uint moneyBox;
        uint adminBonus;
        uint himSelf;
    }

    struct ProsumerRangeConfig {       
        uint assetsDirect;          
        uint bonusValue;           
        uint surplus;   
    }    

    mapping(uint => Course) courses;
    mapping(address => User) public users;
    mapping(address => PendingBonus) public pendingBonus;

    
    mapping(uint8 => ProsumerRangeConfig) prosumerRangeConfig;

    BitacoraPlay bitacoraPlay;
    Career careerPlan;
    
    uint public prosumerPlanPrice = 50e18;

    // Temporales esto se hereda de settings o no
    uint administrativeBalance;
    // address depositToken;
    addre
        
    modifier restricted() override {
        require(bitacoraPlaySettings.isAdmin(msg.sender), "BitacoraPlay: Only admins");
        _;
    }

    modifier onlyContractRestricted(){
        require(address(bitacoraPlay) != address(0), 'required BitacoraPlay address');
        require(address(bitacoraPlay) == msg.sender, 'only BytacoraPlay Contract');
        _;
    }

    constructor(ITRC20 _depositTokenAddress /**IMoneyBox _moneyBox,*/ ) public {
        depositToken = _depositTokenAddress;
        owner = msg.sender;
        administrativeBalance = 0;

        prosumerRangeConfig [1] = ProsumerRangeConfig({assetsDirect: 10, bonusValue: 300e18, surplus: 200e18});
        prosumerRangeConfig [2] = ProsumerRangeConfig({assetsDirect: 40, bonusValue: 900e18, surplus: 1100e18});
        prosumerRangeConfig [3] = ProsumerRangeConfig({assetsDirect: 10, bonusValue: 1200e18, surplus: 1300e18});
    }

    function setContracts(BitacoraPlay _bitacoraPlay, Career _careerPlan) external restricted{        
        bitacoraPlay = bitacoraPlay;
        careerPlan = _careerPlan;
    }

    function setAccumulatedDirectToSeeCourse(address _user) external onlyContractRestricted {
        require(bitacoraPlay.isUserExists(_user));
        users[_user].accumulatedDirectToSeeCourse++;
    }

    function getAccumulatedDirectToSeeCourse(address _user) public view returns(uint){
        return users[_user].accumulatedDirectToSeeCourse;
    }    

    function payProsumerPlan() external {      
        require( bitacoraPlay.isActivatedMembership(msg.sender), "user already active this month.");
        require(careerPlan.isActivatedCareerPlan(msg.sender), "user does not active in Career Plan");
        // require(users[msg.sender].prosumerPlan.approved, "authorization not approved");        
        depositToken.safeTransferFrom(msg.sender, address(this), prosumerPlanPrice);
        users[msg.sender].isProsumer = true;
        users[msg.sender].prosumerLevel = 1;
        if( users[bitacoraPlay.getReferrer(msg.sender)].prosumerBonusRange > 3) {
            users[bitacoraPlay.getReferrer(msg.sender)].accumulatedDirectPlanProsumer ++;
            if(users[bitacoraPlay.getReferrer(msg.sender)].accumulatedDirectPlanProsumer >= prosumerRangeConfig.assetsDirect){
                users[bitacoraPlay.getReferrer(msg.sender)].accumulatedDirectPlanProsumer -= prosumerRangeConfig.assetsDirect;
                users[bitacoraPlay.getReferrer(msg.sender)].pendingBonus.moneyBox += prosumerRangeConfig.bonusValue;
                administrativeBalance += prosumerRangeConfig.surplus;
                emit Prosumer_AvailableAdministrativeBalance(prosumerRangeConfig.surplus);
                emit Prosumer_BonusAvailableToCollectEvent( bitacoraPlay.getReferrer(msg.sender), users[bitacoraPlay.getReferrer(msg.sender)].prosumerBonusRange, 2);
                emit Prosumer_AvailableBalanceForMoneyBox(users[msg.sender].referrer, prosumerRangeConfig.bonusValue);
                users[bitacoraPlay.getReferrer(msg.sender)].prosumerBonusRange ++;
            }
        }
        else{
            administrativeBalance += prosumerPlanPrice;
            emit Prosumer_AvailableAdministrativeBalance(prosumerPlanPrice);
        }
    }

    function buyACourse(address _prosumer, uint8 _prosumerLevel) external {            
        require(bitacoraPlay.isUserExists(msg.sender), "user is not exists");  
        require(bitacoraPlay.isUserExists(_prosumer) && users[_prosumer].isProsumer, "prosumer is not exists");  
        require( bitacoraPlay.isActivatedMembership(msg.sender), "user is not active this month.");
        // faltaria comprobar que este usuario (_prosumer) tiene al menos un curso en el ciclo en que esta el estudiante (msg.sender)
        (uint _assetsDirect, uint _amountToPay, /** uint _promotionBonus*/ ) = bitacoraPlaySettings.getProsumerPerCycleConfig(_prosumerLevel, users[msg.sender].cycle);
        require(users[msg.sender].referredPlan.accumulatedDirectToSeeCourse >= _assetsDirect, "user is not ready to watch this video");
        users[_prosumer].prosumerPlan.accumulatedViewsPerCycle[users[msg.sender].cycle]++;//deberia aumentar el valor que se va acumulando para el bono tambien (_promotionBonus)?

        // checkAndUpdateProsumer(_prosumer);
        // users[_prosumer].pendingBonus.himSelf += _amountToPay;
        // emit AvailableCoursePaymentToProsumer(_prosumer,  msg.sender, _amountToPay);
    }

    // function checkAndUpdateProsumer(address _prosumer) internal {
    //     // if(users[_prosumer].prosumerLevel)
    // }

}