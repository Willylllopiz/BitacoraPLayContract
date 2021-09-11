pragma solidity ^0.6.2;
// SPDX-License-Identifier: MIT

import "./BitacoraPlayBasic.sol";
import "./BitacoraPlay.sol";

contract Career is BitacoraPlayBasic{
    event Career_AvailableBalanceForMoneyBox(address indexed _user, uint _amounnt);
    event Career_AvailableAdministrativeBalance(uint _amounnt); 
    event Career_CompletedBonusEvent(address indexed _user, uint8 indexed _range, uint8 indexed plan);    
    event Career_BonusAvailableToCollectEvent(address indexed _user, uint8 indexed _range, uint8 indexed plan);

    struct User {        
        bool isCareer;
        uint8 careerRange;
        uint accumulatedDirectPlanCareer;
        uint accumulatedPlanCareer;
        bool activeCareerPlan;

    }

    struct CareerRangeConfig {
        uint assetsDirect;
        uint assetsSameNetwork;
        uint bonusValue;
        uint surplus;
    }

    struct PendingBonus {
        uint moneyBox;
        uint adminBonus;
        uint himSelf;
    }

    BitacoraPlay bitacoraPlay;

    address public owner;
    address externalAddress;
    address rootAddress;

    uint public careerPlanPrice = 50e18;
    uint8 public constant ACTIVE_LEVEL = 5;

    mapping(address => User) users;
    mapping(uint8 => CareerRangeConfig) internal careerRangeConfig;
    mapping(address => PendingBonus) public pendingBonus;    

    constructor(ITRC20 _depositTokenAddress, address _externalAddress, address _rootAddress/*, IMoneyBox _moneyBox, BitacoraPlaySettings _bitacoraPlaySettings*/ ,BitacoraPlay _bitacoraPlay) public {
        depositToken = _depositTokenAddress;
        externalAddress = _externalAddress;
        rootAddress = _rootAddress;
        // moneyBox=_moneyBox;
        // bitacoraPlaySettings = _bitacoraPlaySettings;
        bitacoraPlay = _bitacoraPlay;

        careerRangeConfig [1] = CareerRangeConfig({assetsDirect: 30, assetsSameNetwork: 0, bonusValue: 750e18, surplus:0});
        careerRangeConfig [2] = CareerRangeConfig({assetsDirect: 70, assetsSameNetwork: 0, bonusValue: 1750e18, surplus:0});
        careerRangeConfig [3] = CareerRangeConfig({assetsDirect: 0, assetsSameNetwork: 1000, bonusValue: 1800e18, surplus:0});
        careerRangeConfig [4] = CareerRangeConfig({assetsDirect: 0, assetsSameNetwork: 5000, bonusValue: 7200e18, surplus:0});


    }

    function isUserExists(address _user) public view override returns (bool){
        return bitacoraPlay.isUserExists(_user);
    }

    function isActivatedCareerPlan(address _user) public view returns(bool) {
        // return users[_user].isActive;
        return _user !=  rootAddress;
    }  

    // function activateCareerPlan() external{      
    //     require( bitacoraPlay.isActivatedMembership(msg.sender), "user is not active this month.");
    //     payCareerPlanActivation(msg.sender);
    // }

    function payCareerPlanActivation(address _user) private {
        require(bitacoraPlay.isUserExists(_user), "user is not exists. Register first.");
        depositToken.safeTransferFrom(_user, address(this), careerPlanPrice);
        // users[_user].activeCareerPlan = true;
        users[bitacoraPlay.getReferrer(_user)].accumulatedDirectPlanCareer ++;
        updateActivePlanCareer(ACTIVE_LEVEL, bitacoraPlay.getReferrer(_user));
        administrativeBalance +=10e18;
        emit Career_AvailableAdministrativeBalance(10e18);
        globalBalance += careerPlanPrice;
    }

    function updateActivePlanCareer(uint8 _level, address _referrerAddress) private {
        if(_level > 0 && _referrerAddress != rootAddress) {
            users[_referrerAddress].accumulatedPlanCareer ++;
            if (checkCareerRange(_referrerAddress, users[_referrerAddress].careerRange)){
                 if ( 3 > users[_referrerAddress].careerRange){
                     changeCareerRange(_referrerAddress);
                 }
                else{
                     pendingBonus[rootAddress].himSelf += 3e18;
                 }

                emit Career_CompletedBonusEvent(_referrerAddress, users[_referrerAddress].careerRange, 1);                
            }
            updateActivePlanCareer(_level - 1, bitacoraPlay.getReferrer(_referrerAddress));
        }
        return;
    }

     // Check that a user (_userAddress) is in a specified range (_range) in Career Plan
    function checkCareerRange(address _userAddress, uint8 _range) public view returns(bool) {
        return _range <= 1 ? users[ _userAddress ].accumulatedDirectPlanCareer >= careerRangeConfig[_range].assetsDirect :
        users[ _userAddress ].accumulatedPlanCareer >= careerRangeConfig[_range].assetsSameNetwork;
    }

    function changeCareerRange(address _userAddress) private {
        if (users[ _userAddress ].careerRange <= 1 ){
            users[ _userAddress ].accumulatedDirectPlanCareer -= careerRangeConfig[users[_userAddress].careerRange].assetsDirect;
            pendingBonus[_userAddress].adminBonus += careerRangeConfig[users[_userAddress].careerRange].bonusValue;
            emit Career_BonusAvailableToCollectEvent(_userAddress,  users[_userAddress].careerRange, 1);
        }
        if (users[ _userAddress ].careerRange == 2 || users[ _userAddress ].careerRange == 3){
            users[ _userAddress ].accumulatedPlanCareer -= careerRangeConfig[users[_userAddress].careerRange].assetsSameNetwork;
            pendingBonus[_userAddress].moneyBox += careerRangeConfig[users[_userAddress].careerRange].bonusValue;
            emit Career_AvailableBalanceForMoneyBox(_userAddress, careerRangeConfig[users[_userAddress].careerRange].bonusValue);
        }
        emit Career_CompletedBonusEvent(_userAddress, users[_userAddress].careerRange, 1);
        //  Updating CareerRange
        users[ _userAddress ].careerRange ++;
    }
    
    function isCareer(address _userAddress) public view returns(bool){
        return users[_userAddress].isCareer;
    }

    function withdrawUserBonusByAdmin(uint _amount, address _user) external override restricted safeTransferAmount(_amount){
        require(0 < _amount, "BitacoraPlay: Invalid amount");
        require(isCareer(_user) && isUserExists(_user), "user is not Prosumer");
        require(_amount <= pendingBonus[_user].adminBonus, "BitacoraPlay: insufficient funds");
        depositToken.safeTransfer(msg.sender, _amount);
        pendingBonus[_user].adminBonus -= _amount;
        globalBalance -= _amount;
        emit AdminWithdrewUserBonus(msg.sender, _user, _amount);
    }

    function witdrawUserFounds(uint _amount) external override safeTransferAmount(_amount){
        require(isCareer(msg.sender) && isUserExists(msg.sender), "user is not Prosumer");
        require(0 < _amount, "BitacoraPlay: Invalid amount");
        require(_amount <= pendingBonus[msg.sender].himSelf, "BitacoraPlay: insufficient funds");
        depositToken.safeTransfer(msg.sender, _amount);
        pendingBonus[msg.sender].himSelf -= _amount;
        globalBalance -= _amount;
        emit UserWithdrewFunds(msg.sender, _amount);
    }

    function userInvestmentInMoneyBox(uint _amount, uint8 _categoryId) external override safeTransferAmount(_amount){
        require(isCareer(msg.sender) && isUserExists(msg.sender), "user is not exists");
        require(50e18 < _amount, "BitacoraPlay: Invalid amount");//TODO: Verificar con oscar cual debe ser este valor
        require(_amount <= pendingBonus[msg.sender].moneyBox, "BitacoraPlay: insufficient funds");
        depositToken.safeIncreaseAllowance(address(moneyBox), _amount);
        moneyBox.addToBalance( msg.sender, _amount);        
        pendingBonus[msg.sender].moneyBox -= _amount;
        globalBalance -= _amount;
        emit UserInvestmentInMoneyBox(msg.sender, _categoryId, _amount);
    }
}