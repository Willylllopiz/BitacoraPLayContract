pragma solidity ^0.6.2;
// SPDX-License-Identifier: MIT

import "./BitacoraPlayBasic.sol";
import "./ISettingsBasic.sol";
import "./IProsumer.sol";
import "./ICareer.sol";
import "./IBitacoraPlay.sol";

contract BitacoraPlay is BitacoraPlayBasic, IBitacoraPlay {
    event SignUpEvent(address indexed _newUser, uint indexed _userId, address indexed _sponsor, uint _sponsorId);
    // Plan: 1 => ReferredBonus, Plan: 1 => CareerRangeBonus, Plan: 2 => ProsumerRangeBonus, Plan: 3 => ProsumerLevelBonus, Plan:4 AcademicExcellence
    event CompletedBonusEvent(address indexed _user, uint _userId, uint8 indexed _range, uint8 indexed plan);
    event BonusAvailableToCollectEvent(address indexed _user, uint _userId, uint8 indexed _range, uint8 indexed plan);
    event AccumulatedAcademicExcellenceBonus(uint _amount);

    event NewUserChildEvent(address indexed _user, address indexed _sponsor);
    event AvailableBalanceForMoneyBox(address indexed _user, uint _amounnt);
    event AvailableAdministrativeBalance(uint _amounnt);
    event AvailableBalanceForUser(address indexed _user, uint _amount); 
    event CareerPlan_Royalties(address indexed _user, uint amount, uint8 _userLevel);

    struct User {
        uint id;
        address referrer;
        uint8 referRange;
        ReferredPlan referredPlan;
        PendingBonus pendingBonus;
        AcademicInfo academicInfo;
        uint256 activationDate;
    }

    struct ReferredPlan {
        uint accumulatedMembers; //Cantidad acumulada de pagos de hasta el quinto nivel
        uint accumulatedDirectMembers; //cantidad acumulada de referidos directos para uso de los bonos
        uint accumulatedPayments; //cantidad acumulada de pagos para la distribucion del bono actual del usuario
        
    }

    struct AcademicInfo{
        uint accumulatedDirectToSeeCourse;
        uint coursePay; 
        uint8 cycle;
    }

     struct PendingBonus {
        uint moneyBox;
        uint adminBonus;
        uint himSelf;
        uint referralDirectPayments;
    }

    struct ReferredRangeConfig {
        uint assetsDirect;
        uint assetsSameNetwork;
        uint8 qualificationPeriod;

        uint bonusValue;
        uint surplus;
        uint remainderVehicleBonus;
    }
    
    struct ReferredDistributionsPayments {
        uint referralDirectPayment; //60% of referralPlanPrice.
        uint referralBonus;
        uint careerPlanBonus;
        uint coursePay;
        uint admin;
    }

    mapping(address => User) users;
    mapping(uint => address) internal idToAddress; 
    IProsumer prosumerContract;
    ICareer careerContract;

    address externalAddress;
    address rootAddress;

    uint public lastUserId = 2;
    uint public referralPlanPrice = 35e18;
    uint8 public constant ACTIVE_LEVEL = 5;
    uint8 numberOfRange;
    uint public accumulatedAcademicExcellenceBonus;        

    ReferredDistributionsPayments referredDistributionsPaymentsConfig;
    mapping(uint8 => ReferredRangeConfig) internal referredRangeConfig;
    uint [] careerPlanPercentageConfig;

    modifier onlyProsumerContractRestricted(){
        require(!_locked, "BitacoraPlay: locked Contract");
        require(address(msg.sender) != address(0), 'BitacoraPlay: required valid address');
        require(address(prosumerContract) == msg.sender, 'BitacoraPlay: only Prosumer Contract');
        _;
    }

    // modifier onlyCareerContractRestricted(){
    //     require(address(msg.sender) != address(0), 'BitacoraPlay: required valid address');
    //     require(address(careerContract) == msg.sender, 'BitacoraPlay: only Career Contract');
    //     _;
    // }

    constructor(address _externalAddress, address _rootAddress) public {
        globalBalance = 0;
        administrativeBalance = 0;   
        accumulatedAcademicExcellenceBonus = 0;

        externalAddress = _externalAddress;
        rootAddress = _rootAddress;
        users[rootAddress].id = 1;
        users[rootAddress].referrer = address(0);
        idToAddress[1] = rootAddress;
        users[_rootAddress].referRange = 5;

        _owner = msg.sender;
        _locked = true;
    }

    function initialize(ITRC20 _depositTokenAddress, IProsumer _prosumerContract, ICareer _careerPlan,  IMoneyBox _moneyBox, ISettingsBasic _settingsBasic) external onlyOwner{        
        depositToken = _depositTokenAddress;
        careerContract = _careerPlan;
        prosumerContract = _prosumerContract;
        moneyBox = _moneyBox;
        settingsBasic = _settingsBasic;

        numberOfRange = 4;
        // The rookie bonus setup is unnecessary, it is not registered yet
        referredRangeConfig [1] = ReferredRangeConfig({
            assetsDirect: 30,
            assetsSameNetwork: 3000,
            qualificationPeriod: 1,
            bonusValue: 500e18,
            surplus: 40e18, 
            remainderVehicleBonus: 540e18
        });
        // Leader Bonus Configuration
        referredRangeConfig[2] = ReferredRangeConfig({
            assetsDirect: 100,
            assetsSameNetwork: 7000,
            qualificationPeriod: 2,
            bonusValue: 1800e18,
            surplus: 0,
            remainderVehicleBonus: 3240e18
        });
        // Guru Bonus Configuration
        referredRangeConfig[3] = ReferredRangeConfig({
            assetsDirect: 300,
            assetsSameNetwork: 20000,
            qualificationPeriod: 2,
            bonusValue: 4500e18,
            surplus: 0e18,
            remainderVehicleBonus: 9900e18
        });
        // GuruVehicle Bonus Configuration
        referredRangeConfig[4] = ReferredRangeConfig({
            assetsDirect: 300,
            assetsSameNetwork: 20000,
            qualificationPeriod: 2,
            bonusValue: 0e18,
            surplus: 0e18,
            remainderVehicleBonus: 14400e18
        });

        referredDistributionsPaymentsConfig = ReferredDistributionsPayments({
            referralDirectPayment: 18e18, //60% of referralPlanPrice.
            referralBonus: 0.36e18,//0.36 * 5 = 1.8 referral bonus five level
            careerPlanBonus: 0.6e18,
            coursePay: 2.4e18,
            admin: 9.2e18 //Surplus to Admin
        });        
        
        // Career Plan Five Level: 3e18
        careerPlanPercentageConfig[4] = 0.3e18;
        careerPlanPercentageConfig[3] = 0.6e18;
        careerPlanPercentageConfig[2] = 0.9e18;
        careerPlanPercentageConfig[1] = 1.2e18;

        _locked = false;
    }

    fallback() external {
        // require(msg.value == referralPlanPrice, "invalid registration cost");
        if(msg.data.length == 0) {
            return registration(msg.sender, rootAddress);
        }
        registration(msg.sender, bytesToAddress(msg.data));
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }    

    function getReferrer(address _userAddress) public view override returns(address){
        require(isUserExists(_userAddress) && _userAddress != rootAddress, 'user not valid');
        return users[_userAddress].referrer;
    }

    function isUserExists(address user) public view override(IBitacoraPlay, BitacoraPlayBasic) returns (bool) {
        return (users[user].id != 0);
    }    

    function isActivatedMembership(address _user) public view override returns(bool) {
        require(isUserExists(_user), "BitacoraPlay: user is not exists. Register first.");
        return block.timestamp <=  users[_user].activationDate;
    }

    function signUp(address _referrerAddress) external returns(string memory){        
        registration(msg.sender, _referrerAddress);        
        return "registration successful!!";
    }

    function registration(address userAddress, address referrerAddress) private {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");

        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");

        idToAddress[lastUserId] = userAddress;
        users[userAddress].id = lastUserId;
        users[userAddress].referrer = referrerAddress;
        users[userAddress].referRange = 1;//revisar si empieza en rookie o junior   
        lastUserId++;

        payMonth(userAddress);
        emit NewUserChildEvent(userAddress, referrerAddress);
        emit SignUpEvent(userAddress, users[userAddress].id, referrerAddress, users[referrerAddress].id);
    }   

    function payMonth(address _user) private {
        require(isUserExists(_user), "BitacoraPlay: user is not exists. Register first.");
        require(address(prosumerContract) != address(0), "BitacoraPlay: Not Prosumer implementation");
        depositToken.safeTransferFrom(_user, address(this), referralPlanPrice);
        globalBalance += referralPlanPrice;
        users[_user].activationDate =  block.timestamp + 30 days;

        User storage sponsorInfo = users[users[_user].referrer];
        sponsorInfo.referredPlan.accumulatedDirectMembers ++;
        sponsorInfo.pendingBonus.referralDirectPayments += referredDistributionsPaymentsConfig.referralDirectPayment;        
        sponsorInfo.academicInfo.accumulatedDirectToSeeCourse ++;
        sponsorInfo.academicInfo.coursePay += referredDistributionsPaymentsConfig.coursePay;
        // prosumerContract.setAccumulatedDirectToSeeCourse(users[_user].referrer);

        accumulatedAcademicExcellenceBonus += referredDistributionsPaymentsConfig.careerPlanBonus;
       
        updateActiveMembers(ACTIVE_LEVEL, users[_user].referrer);
        updateCareerPlan(1, users[_user].referrer);

        administrativeBalance += referredDistributionsPaymentsConfig.admin;
        emit AvailableAdministrativeBalance(referredDistributionsPaymentsConfig.admin);
    }

    function payMonthly() external {
        require( !isActivatedMembership(msg.sender), "user already active this month.");
        payMonth(msg.sender);
    }

    function updateActiveMembers(uint8 _level, address _referrerAddress) private {
        if(_level > 0){
            if(_referrerAddress != rootAddress){
                users[_referrerAddress].referredPlan.accumulatedMembers ++;
                if(users[_referrerAddress].referRange > numberOfRange){
                    users[_referrerAddress].referredPlan.accumulatedPayments += referredDistributionsPaymentsConfig.referralBonus;                
                    if (checkRange(_referrerAddress, users[_referrerAddress].referRange)){
                        emit CompletedBonusEvent(_referrerAddress, users[_referrerAddress].id, users[_referrerAddress].referRange, 0);
                        changeRange(_referrerAddress);
                    }                   
                }
                else{
                    administrativeBalance += referredDistributionsPaymentsConfig.referralBonus;
                    emit AvailableAdministrativeBalance(referredDistributionsPaymentsConfig.referralBonus);
                }
                updateActiveMembers(_level - 1, users[_referrerAddress].referrer);
            }
            else{
                administrativeBalance += referredDistributionsPaymentsConfig.referralBonus * _level;
                emit AvailableAdministrativeBalance(referredDistributionsPaymentsConfig.referralBonus * _level);
            }
        }
        return;
        
    }   

    // Check that a user (_userAddress) is in a specified range (_range) in Referred Plan
    function checkRange(address _userAddress, uint8 _range) public view returns(bool) {
        require(isUserExists(_userAddress), "BitacoraPlay: user is not exists. Register first.");
        require(_range > 0, "BitacoraPlay: range not valid");
        if(_range > numberOfRange ) { return false;} //it is in last range!!!
        return users[ _userAddress ].referredPlan.accumulatedMembers >= (referredRangeConfig[_range].assetsSameNetwork *
        referredRangeConfig[_range].qualificationPeriod ) &&
        users[ _userAddress ].referredPlan.accumulatedDirectMembers >= referredRangeConfig[_range].assetsDirect;
    }

    function changeRange(address userAddress) private {
        require(users[userAddress].referredPlan.accumulatedPayments >= 
            referredRangeConfig[users[userAddress].referRange].bonusValue + 
            referredRangeConfig[users[userAddress].referRange].surplus + 
            referredRangeConfig[users[userAddress].referRange].remainderVehicleBonus,
            "BitacoraPlay: insufficient accumulated payments");
        // users[userAddress].referredPlan.accumulatedPayments -= referredRangeConfig[users[userAddress].referRange].bonusValue;
        if (users[userAddress].referRange == 1){
            users[userAddress].pendingBonus.moneyBox += referredRangeConfig[users[userAddress].referRange].bonusValue;
            users[userAddress].referredPlan.accumulatedPayments -= referredRangeConfig[users[userAddress].referRange].bonusValue;
            emit AvailableBalanceForMoneyBox(userAddress, referredRangeConfig[users[userAddress].referRange].bonusValue);
        }
        else{
            users[userAddress].pendingBonus.adminBonus += referredRangeConfig[users[userAddress].referRange].bonusValue;
        }
        if(referredRangeConfig[users[userAddress].referRange].surplus > 0){
            administrativeBalance += referredRangeConfig[users[userAddress].referRange].surplus;
            users[userAddress].referredPlan.accumulatedPayments -= referredRangeConfig[users[userAddress].referRange].surplus;
            emit AvailableAdministrativeBalance(referredRangeConfig[users[userAddress].referRange].surplus);
        }        
        emit BonusAvailableToCollectEvent(userAddress, users[userAddress].id, users[userAddress].referRange, 0);

        // Updating number of assets of the same network
        users[userAddress].referredPlan.accumulatedMembers = users[userAddress].referredPlan.accumulatedMembers - referredRangeConfig[users[userAddress].referRange].assetsSameNetwork >=0
        ? users[userAddress].referredPlan.accumulatedMembers - referredRangeConfig[users[userAddress].referRange].assetsSameNetwork
        : 0;
        // Updating number of direct assets
        users[userAddress].referredPlan.accumulatedDirectMembers = users[userAddress].referredPlan.accumulatedDirectMembers - referredRangeConfig[users[userAddress].referRange].assetsDirect >=0
        ? users[userAddress].referredPlan.accumulatedDirectMembers - referredRangeConfig[users[userAddress].referRange].assetsDirect
        : 0;
        //  Updating ReferredRange
        users[userAddress].referRange ++;
    }
    
    // Asignacion a partir de una lista de usuarios el bono a la excelencia academica!!!
    function setUsersAcademicExcellenceBonus( address[] memory _winningUsers) public restricted{
        require(_winningUsers.length  < 0, "BitacoraPlay: empty list");
        require(accumulatedAcademicExcellenceBonus/_winningUsers.length  < 0, "BitacoraPlay: not valid individual amount");
        for (uint256 index = 0; index < _winningUsers.length; index++) {
            require(isUserExists(_winningUsers[index]), "BitacoraPlay: user is not exists.");
            users[_winningUsers[index]].pendingBonus.himSelf += accumulatedAcademicExcellenceBonus/_winningUsers.length;
            emit BonusAvailableToCollectEvent(_winningUsers[index], users[_winningUsers[index]].id, 0, 4);
            emit AvailableBalanceForUser(_winningUsers[index], accumulatedAcademicExcellenceBonus/_winningUsers.length);
        }
    }

// Start Region Career
    function updateCareerPlan(uint8 _level, address _referrerAddress) private{
        require(address(careerContract) != address(0), "BitacoraPlay: Not Career implementation");
        if(_level > 0 && _level < 4){
            if(_referrerAddress != rootAddress && careerContract.isActive(_referrerAddress) && isActivatedMembership(_referrerAddress)){
                users[_referrerAddress].pendingBonus.himSelf += careerPlanPercentageConfig[_level];
                emit CareerPlan_Royalties(_referrerAddress, careerPlanPercentageConfig[_level], _level);
            }
            else{
                administrativeBalance += careerPlanPercentageConfig[_level];
                emit AvailableAdministrativeBalance(careerPlanPercentageConfig[_level]);
            }
            updateCareerPlan(_level + 1, users[_referrerAddress].referrer);
        }
        return;
    }

// End Region Career   

// Start Region Prosumer
    function buyCourse(uint _courseId) external {
        (uint _courseCost) = prosumerContract.getTransferBalanceByCourse(_courseId, users[msg.sender].academicInfo.accumulatedDirectToSeeCourse);
        require(_courseCost > 0 , 'Prosumer: you do not have enough direct referrals');
        require(_courseCost <= users[msg.sender].academicInfo.coursePay, 'Prosumer: balance of user is not valid');        
        (address _prosumer, uint _courseGain, uint _moneyBox, uint _adminBonus, uint _himself, uint8 _level, uint8 _plan) = prosumerContract.buyCourse(_courseId, msg.sender);       
        setProsumerPendingBonus(_prosumer, _moneyBox, _adminBonus, (_himself + _courseGain), _level, _plan);
        users[msg.sender].academicInfo.coursePay -= _courseCost;
    }

    function setProsumerPendingBonus(address _user, uint _moneyBox, uint _adminBonus, uint _himself, uint8 _level, uint8 _plan) internal {
        if(_moneyBox > 0){
            users[_user].pendingBonus.moneyBox += _moneyBox;
            emit AvailableBalanceForMoneyBox(_user, _moneyBox);
        }
        if(_adminBonus > 0){
            administrativeBalance += _adminBonus;
            emit AvailableAdministrativeBalance(_adminBonus);
        }
        if(_himself > 0){
            users[_user].pendingBonus.himSelf += _himself;
            emit AvailableBalanceForUser(_user, _himself);
        }
        if(_plan != 0 ){
            emit BonusAvailableToCollectEvent(_user, users[_user].id, _level, _plan);  
        }              
    }

    function getAccumulatedDirectToSeeCourse(address _userAddress) external view override(IBitacoraPlay) returns(uint){
        require(isUserExists(_userAddress), "BitacoraPlay: user is not Exist");
        return users[_userAddress].academicInfo.accumulatedDirectToSeeCourse;
    }
// End Region Prosumer

// Start Region Withdrawals
    function withdrawUserBonusByAdmin(uint _amount, address _user) external override restricted safeTransferAmount(_amount){
        require(0 < _amount, "BitacoraPlay: Invalid amount");
        require(isUserExists(_user), "BitacoraPlay: user is not Exist");
        require(_amount <= users[_user].pendingBonus.adminBonus, "BitacoraPlay: insufficient funds");
        depositToken.safeTransfer(msg.sender, _amount);
        globalBalance -= _amount;
        users[_user].pendingBonus.adminBonus -= _amount;
        emit AdminWithdrewUserBonus(msg.sender, _user, _amount);
    }

    function witdrawUserFoundsOfReferredDirect() external {
        require(isUserExists(msg.sender), "BitacoraPlay: user is not exists");
        require(isActivatedMembership(msg.sender), "BitacoraPlay: has not paid monthly payment");
        require(0 < users[msg.sender].pendingBonus.referralDirectPayments, "BitacoraPlay: Invalid amount");
        require(users[msg.sender].pendingBonus.referralDirectPayments >= 100e18, "BitacoraPlay: insufficient funds");
        require(users[msg.sender].pendingBonus.referralDirectPayments <= globalBalance, "BitacoraPlay: insufficient funds");
        users[msg.sender].pendingBonus.referralDirectPayments = 0;
        depositToken.safeTransfer(msg.sender, users[msg.sender].pendingBonus.referralDirectPayments);
        globalBalance -= users[msg.sender].pendingBonus.referralDirectPayments;
        emit UserWithdrewFunds(msg.sender, users[msg.sender].pendingBonus.referralDirectPayments);
    }

    function witdrawUserFounds(uint _amount) external override safeTransferAmount(_amount){
        require(isUserExists(msg.sender), "user is not exists");
        require(0 < _amount, "BitacoraPlay: Invalid amount");
        require(_amount <= users[msg.sender].pendingBonus.himSelf, "BitacoraPlay: insufficient funds");
        users[msg.sender].pendingBonus.himSelf -= _amount;
        depositToken.safeTransfer(msg.sender, _amount);
        globalBalance -= _amount;
        emit UserWithdrewFunds(msg.sender, _amount);
    }

    function userInvestmentInMoneyBox(uint _amount, uint8 _categoryId) external override safeTransferAmount(_amount){
        require(isUserExists(msg.sender), "user is not exists");
        require(50e18 < _amount, "BitacoraPlay: Invalid amount");//TODO: Verificar con oscar cual debe ser este valor
        require(_amount <= users[msg.sender].pendingBonus.moneyBox, "BitacoraPlay: insufficient funds");
        moneyBox.addToBalance( msg.sender, _amount);        
        users[msg.sender].pendingBonus.moneyBox -= _amount;
        depositToken.safeIncreaseAllowance(address(moneyBox), _amount);
        globalBalance -= _amount;
        emit UserInvestmentInMoneyBox(msg.sender, _categoryId, _amount);
    }
// End Region Withdrawals
}