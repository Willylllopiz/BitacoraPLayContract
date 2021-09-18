pragma solidity ^0.6.2;
// SPDX-License-Identifier: MIT

import "./BitacoraPlayBasic.sol";
import "./ISettingsBasic.sol";
import "./IBitacoraPlay.sol";

contract BitacoraPlay is BitacoraPlayBasic, IBitacoraPlay {
    event SignUpEvent(address indexed _newUser, uint indexed _userId, address indexed _sponsor, uint _sponsorId);
    // Plan: 1 => ReferredBonus, Plan: 1 => CareerRangeBonus, Plan: 2 => ProsumerRangeBonus, Plan: 3 => ProsumerLevelBonus, Plan:4 AcademicExcellence
    event BonusAvailableToCollectEvent(address indexed _user, uint _userId, uint8 indexed _range, uint8 indexed plan);
    event AccumulatedAcademicExcellenceBonus(uint _amount);

    event NewUserChildEvent(address indexed _user, address indexed _sponsor);
    event AvailableBalanceForMoneyBox(address indexed _user, uint _amount);
    event AvailableAdministrativeBalance(uint _amonnt);
    event AvailableBalanceForUser(address indexed _user, uint _amount); 
    event AvailableAdministrativeBalanceForUserBonus(address indexed _user, uint _amount);
    event CareerPlan_Royalties(address indexed _user, uint amount, uint8 _userLevel);    
    event ProsumerPlan_NewProsumer(address indexed _user, uint8 _prosumerLevel);    
    event ProsumerPlan_SetProsumerLevelByAdmin(address indexed _admin, address indexed _user, uint8 _level);

    event Course_NewCourse(string indexed _courseId, uint _contractCourseId);

    struct User {
        uint id;
        address referrer;        
        uint balance; 

        bool careerIsActive;
        bool prosumerIsActive;
        BasicPlan referredPlan;
        BasicPlan careerPlan;
        BasicPlan prosumerPlan;

        PendingPayments pendingPayments;
        AcademicInfo academicInfo;
        ProsumerInfo prosumerInfo;
        uint256 activationDate;
    }

    struct BasicPlan {        
        uint8 range;
        uint accumulatedIndirectMembers; 
        uint accumulatedDirectMembers;    
    }

    struct ProsumerInfo {
        uint8 degree;
        uint8 cycle;
    }

    struct AcademicInfo{
        uint accumulatedDirectToSeeCourse;
        uint coursePay; 
        uint8 cycle;
    }

     struct PendingPayments {
        uint moneyBox;
        uint adminBonus;
        uint himSelf;
        uint careerPlanRoyalties;
        uint referralDirectPayments;
    }

    struct Course {
        uint id;
        uint8 cycle;
        uint8 degree;
        address prosumerAuthor;

        uint extraPrice;
        uint amountToProsumer;
        mapping(address => bool) usersViews;
    }

    struct BasicRangeConfig{
        uint assetsDirect;
        uint directPayment;
        uint assetsIndirect;
        uint indirectPayment;
        uint moneyBox;
        uint adminBonus;
        uint himSelf;
        uint surplus;
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

    mapping(uint => Course) public courses;

    address externalAddress;
    address rootAddress;

    uint public lastUserId = 2;
    uint public courseId = 1;  
    uint public referralPlanPrice = 35e18;
    uint public careerPlanPrice = 50e18;
    uint public prosumerPlanPrice = 50e18;
    uint8 public constant REFERRED_ACTIVE_LEVEL = 5;
    uint8 public constant CAREER_ACTIVE_LEVEL = 5;
    uint8 public constant PROSUMER_ACTIVE_LEVEL = 1;
    uint public accumulatedAcademicExcellenceBonus;        

    ReferredDistributionsPayments referredDistributionsPaymentsConfig;
    uint [] careerPlanRoyaltiesConfig;
    mapping(uint8 => BasicRangeConfig) internal referredRangeConfig;
    uint8 referredRangeCountConfig;
    mapping(uint8 => BasicRangeConfig) internal careerRangeConfig;
    uint careerRangeCountConfig;
    mapping(uint8 => BasicRangeConfig) internal prosumerRangeConfig;
    uint prosumerRangeCountConfig;
    mapping(uint8 => uint8) degreePerCycleConfig;

    constructor(address _externalAddress, address _rootAddress) public {
        globalBalance = 0;
        administrativeBalance = 0;   
        accumulatedAcademicExcellenceBonus = 0;

        externalAddress = _externalAddress;
        rootAddress = _rootAddress;
        users[rootAddress].id = 1;
        users[rootAddress].referrer = address(0);
        idToAddress[1] = rootAddress;
        users[_rootAddress].referredPlan.range = 5;

        _owner = msg.sender;
        _locked = true;
    }

    function initialize(ITRC20 _depositTokenAddress, IMoneyBox _moneyBox, ISettingsBasic _settingsBasic) external onlyOwner{        
        depositToken = _depositTokenAddress;
        moneyBox = _moneyBox;
        settingsBasic = _settingsBasic;

        referredDistributionsPaymentsConfig = ReferredDistributionsPayments({
            referralDirectPayment: 18e18, //60% of referralPlanPrice.
            referralBonus: 0.36e18,//0.36 * 5 = 1.8 referral bonus five level
            careerPlanBonus: 0.6e18,
            coursePay: 2.4e18,
            admin: 9.2e18 //Surplus to Admin
        });  

        referredRangeCountConfig = 4;
        // The rookie bonus setup is unnecessary, it is not registered yet
        referredRangeConfig [1] = BasicRangeConfig({
            assetsDirect: 30,
            assetsIndirect: 3000,
            directPayment: 18e18, //60% of referralPlanPrice.
            indirectPayment: 0.36e18,//0.36 * 5 = 1.8 referral bonus five level
            moneyBox: 500e18,    
            adminBonus:0,
            himSelf:0,      
            surplus: 40e18
        });
        // Leader Bonus Configuration
        referredRangeConfig[2] = BasicRangeConfig({
            assetsDirect: 100,
            assetsIndirect: 14000,
            directPayment: 18e18, //60% of referralPlanPrice.
            indirectPayment: 0.36e18,//0.36 * 5 = 1.8 referral bonus five level
            moneyBox: 0,
            adminBonus: 1800e18,
            himSelf: 0,
            surplus: 0
        });
        // Guru Bonus Configuration
        referredRangeConfig[3] = BasicRangeConfig({
            assetsDirect: 300,
            assetsIndirect: 40000,
            directPayment: 18e18, //60% of referralPlanPrice.
            indirectPayment: 0.36e18,//0.36 * 5 = 1.8 referral bonus five level
            moneyBox: 0,
            adminBonus: 4500e18,
            himSelf: 0,
            surplus: 0
        });
        // GuruVehicle Bonus Configuration
        referredRangeConfig[4] = BasicRangeConfig({
            assetsDirect: 300,
            assetsIndirect: 40000,
            directPayment: 18e18, //60% of referralPlanPrice.
            indirectPayment: 0.36e18,//0.36 * 5 = 1.8 referral bonus five level
            moneyBox: 0,
            adminBonus: 28080e18,
            himSelf: 0,
            surplus: 0
        });      
        
        // Career Plan Five Level Royalties: 3e18
        careerPlanRoyaltiesConfig[4] = 0.3e18;
        careerPlanRoyaltiesConfig[3] = 0.6e18;
        careerPlanRoyaltiesConfig[2] = 0.9e18;
        careerPlanRoyaltiesConfig[1] = 1.2e18;

        careerRangeCountConfig = 4;
        careerRangeConfig [1] = BasicRangeConfig({
            assetsDirect: 30, 
            directPayment: 25e18,
            assetsIndirect: 0, 
            indirectPayment: 0,
            moneyBox: 0,
            adminBonus: 750e18,
            himSelf: 0,
            surplus:0
        });
        careerRangeConfig [2] = BasicRangeConfig({
            assetsDirect: 70, 
            directPayment: 25e18,
            assetsIndirect: 0, 
            indirectPayment: 0,
            moneyBox: 0,
            adminBonus: 1750e18,
            himSelf: 0,  
            surplus:0
        });
        careerRangeConfig [3] = BasicRangeConfig({
            assetsDirect: 0,
            directPayment: 0,
            assetsIndirect: 1000, 
            indirectPayment: 1e18,
            moneyBox: 1800e18, 
            adminBonus: 0,
            himSelf: 0,
            surplus:0
        });
        careerRangeConfig [4] = BasicRangeConfig({
            assetsDirect: 0, 
            directPayment: 0,
            assetsIndirect: 5000, 
            indirectPayment: 2e18,
            moneyBox: 7200e18,  
            adminBonus: 0,
            himSelf: 0,
            surplus:0
        });

        prosumerRangeCountConfig = 3;
        prosumerRangeConfig [1] = BasicRangeConfig({ 
            assetsDirect: 10, 
            directPayment: 40e18,
            assetsIndirect: 0, 
            indirectPayment: 0,
            moneyBox: 300e18,  
            adminBonus: 0,
            himSelf: 0,
            surplus:200e18
        });
        prosumerRangeConfig [2] = BasicRangeConfig({
            assetsDirect: 40, 
            directPayment: 40e18,
            assetsIndirect: 0, 
            indirectPayment: 0,
            moneyBox: 900e18,  
            adminBonus: 0,
            himSelf: 0,
            surplus:1100e18
        });
        prosumerRangeConfig [3] = BasicRangeConfig({
            assetsDirect: 10,   
            directPayment: 40e18,
            assetsIndirect: 0, 
            indirectPayment: 0,
            moneyBox: 1200e18,  
            adminBonus: 0,
            himSelf: 0,
            surplus:1300e18            
        });


        degreePerCycleConfig[1] = 1;
        degreePerCycleConfig[2] = 3;
        degreePerCycleConfig[3] = 6;

        _locked = false;
    }

    fallback() external {
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

    function setPendingPayments(address _user, uint _moneyBox, uint _adminBonus, uint _himself, uint _adminBalance,uint8 _level, uint8 _plan) internal {
        if(_moneyBox > 0){
            users[_user].pendingPayments.moneyBox += _moneyBox;
            emit AvailableBalanceForMoneyBox(_user, _moneyBox);
        }
        if(_adminBonus > 0){
            users[_user].pendingPayments.adminBonus += _adminBonus;//TODO: homogenizar esto para todos los planes
            emit AvailableAdministrativeBalanceForUserBonus(_user, _adminBonus);
        }
        if(_himself > 0){
            users[_user].pendingPayments.himSelf += _himself;
            emit AvailableBalanceForUser(_user, _himself);
        }
        if(_adminBalance > 0){
            administrativeBalance += _adminBalance;
            emit AvailableAdministrativeBalance(_adminBalance);
        }
        if(_plan != 0 ){
            emit BonusAvailableToCollectEvent(_user, users[_user].id, _level, _plan);  
        }              
    }  

    function getPendingPayments(address _user) public view returns(uint, uint, uint, uint){
        return (
            users[_user].pendingPayments.moneyBox,
            users[_user].pendingPayments.himSelf,
            users[_user].pendingPayments.adminBonus,
            users[_user].pendingPayments.careerPlanRoyalties
        );
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
        users[userAddress].referredPlan.range = 1;//revisar si empieza en rookie o junior   
        lastUserId++;

        payMonth(userAddress);
        emit NewUserChildEvent(userAddress, referrerAddress);
        emit SignUpEvent(userAddress, users[userAddress].id, referrerAddress, users[referrerAddress].id);
    }   

    function payMonthly() external {
        require( !isActivatedMembership(msg.sender), "user already active this month.");
        payMonth(msg.sender);
    }

    function payMonth(address _user) private {
        require(isUserExists(_user), "BitacoraPlay: user is not exists. Register first.");
        depositToken.safeTransferFrom(_user, address(this), referralPlanPrice);
        globalBalance += referralPlanPrice;
        users[_user].activationDate =  block.timestamp + 30 days;

        User storage _sponsorInfo = users[users[_user].referrer];
        _sponsorInfo.referredPlan.accumulatedDirectMembers ++;
        _sponsorInfo.balance += referredRangeConfig[_sponsorInfo.referredPlan.range].directPayment;
        _sponsorInfo.pendingPayments.referralDirectPayments += referredDistributionsPaymentsConfig.referralDirectPayment; 
        if(_sponsorInfo.pendingPayments.referralDirectPayments >= 100e18){
            setPendingPayments(users[_user].referrer, 0, 0, _sponsorInfo.pendingPayments.referralDirectPayments, 0, 0, 0);
        }      
        _sponsorInfo.academicInfo.accumulatedDirectToSeeCourse ++;
        _sponsorInfo.academicInfo.coursePay += referredDistributionsPaymentsConfig.coursePay;

        accumulatedAcademicExcellenceBonus += referredDistributionsPaymentsConfig.careerPlanBonus;
       
        updateMembers(REFERRED_ACTIVE_LEVEL, users[_user].referrer, 1);
        updateCareerPlanRoyalties(1, users[_user].referrer);

        administrativeBalance += referredDistributionsPaymentsConfig.admin;
        emit AvailableAdministrativeBalance(referredDistributionsPaymentsConfig.admin);
    }     

    function updateMembers(uint _level, address _userAddress, uint8 _plan) internal {
        if(_level > 0){
            if(_userAddress != rootAddress){
                (BasicPlan storage _basicPlan, BasicRangeConfig storage _config, uint _rangeCountConfig) = 
                    _plan == 1 ?
                        (users[_userAddress].referredPlan, referredRangeConfig[users[_userAddress].referredPlan.range], referredRangeCountConfig) 
                        : _plan == 2 
                            ? (users[_userAddress].careerPlan, careerRangeConfig[users[_userAddress].careerPlan.range], careerRangeCountConfig) 
                            : (users[_userAddress].prosumerPlan, prosumerRangeConfig[users[_userAddress].prosumerPlan.range], prosumerRangeCountConfig);

                _basicPlan.accumulatedIndirectMembers ++;

                if(_basicPlan.range <= _rangeCountConfig){
                    users[_userAddress].balance += _config.indirectPayment;                                    
                    if (_basicPlan.range <= referredRangeCountConfig 
                    ? users[ _userAddress ].referredPlan.accumulatedIndirectMembers >= (referredRangeConfig[_basicPlan.range].assetsIndirect) 
                    && users[ _userAddress ].referredPlan.accumulatedDirectMembers >= referredRangeConfig[_basicPlan.range].assetsDirect 
                    : false){
                        require(users[_userAddress].balance >= 
                            (referredRangeConfig[_basicPlan.range].moneyBox 
                                + referredRangeConfig[_basicPlan.range].adminBonus 
                                + referredRangeConfig[_basicPlan.range].himSelf 
                                + referredRangeConfig[_basicPlan.range].surplus
                            ),
                            "BitacoraPlay: Invalid Bonus Payment"
                        );
                        setPendingPayments(
                            _userAddress, 
                            referredRangeConfig[_basicPlan.range].moneyBox, 
                            referredRangeConfig[_basicPlan.range].adminBonus, 
                            referredRangeConfig[_basicPlan.range].himSelf, 
                            referredRangeConfig[_basicPlan.range].surplus,
                            _basicPlan.range, 
                            1                        
                        );
                        // Updating Range 
                        _basicPlan.range ++;
                        _basicPlan.accumulatedIndirectMembers -= (referredRangeConfig[_basicPlan.range].assetsIndirect );
                        _basicPlan.accumulatedDirectMembers -= referredRangeConfig[_basicPlan.range].assetsDirect;
                        users[_userAddress].balance -= referredRangeConfig[_basicPlan.range].moneyBox + referredRangeConfig[_basicPlan.range].adminBonus + referredRangeConfig[_basicPlan.range].himSelf + referredRangeConfig[_basicPlan.range].surplus;
                    }                   
                }
                else{
                    administrativeBalance += referredDistributionsPaymentsConfig.referralBonus;
                    emit AvailableAdministrativeBalance(referredDistributionsPaymentsConfig.referralBonus);
                }
                updateMembers(_level - 1, users[_userAddress].referrer, _plan);
            }
            else{
                administrativeBalance += referredDistributionsPaymentsConfig.referralBonus * _level;
                emit AvailableAdministrativeBalance(referredDistributionsPaymentsConfig.referralBonus * _level);
            }
        }
        return;
    }

// Start Region Career
    function payCareerPlanActivation(address _user) private {
        require(isUserExists(_user), "BitacoraPlay: user is not exists. Register first.");
        require(isActivatedMembership(_user), "BitacoraPlay: has not paid monthly payment");
        require(!users[_user].careerIsActive, "Career: user is already active in career plan");
        depositToken.safeTransferFrom(_user, address(this), careerPlanPrice);
        globalBalance += careerPlanPrice;

        users[_user].careerIsActive = true;
        users[_user].careerPlan.range = 1;
        users[_user].academicInfo.cycle = 1;

        User storage _sponsor = users[users[_user].referrer];
        _sponsor.careerPlan.accumulatedDirectMembers ++;
        _sponsor.balance += careerRangeConfig[_sponsor.careerPlan.range].directPayment;
        updateMembers(CAREER_ACTIVE_LEVEL, users[_user].referrer, 2);
        
        administrativeBalance +=10e18;
        emit AvailableAdministrativeBalance(10e18);
    }    

    function updateCareerPlanRoyalties(uint8 _level, address _referrerAddress) private{
        if(_level > 0 && _level < careerPlanRoyaltiesConfig.length-1){
            if(_referrerAddress != rootAddress && users[_referrerAddress].careerIsActive && isActivatedMembership(_referrerAddress)){
                users[_referrerAddress].pendingPayments.careerPlanRoyalties += careerPlanRoyaltiesConfig[_level];
                emit CareerPlan_Royalties(_referrerAddress, careerPlanRoyaltiesConfig[_level], _level);
            }
            else{
                administrativeBalance += careerPlanRoyaltiesConfig[_level];
                emit AvailableAdministrativeBalance(careerPlanRoyaltiesConfig[_level]);
            }
            updateCareerPlanRoyalties(_level + 1, users[_referrerAddress].referrer);
        }
        return;
    }
        
    // Distribute the academic excellence bonus to a list of users !!!
    function setUsersAcademicExcellenceBonus( address[] memory _winningUsers) public restricted{
        require(_winningUsers.length  > 0, "BitacoraPlay: empty list");
        require(accumulatedAcademicExcellenceBonus/_winningUsers.length  > 0, "BitacoraPlay: not valid individual amount");
        uint toDistribute = accumulatedAcademicExcellenceBonus/_winningUsers.length;
        for (uint256 index = 0; index < _winningUsers.length; index++) {
            require(isUserExists(_winningUsers[index]), "BitacoraPlay: user is not exists.");
            require(accumulatedAcademicExcellenceBonus > toDistribute, "BitacoraPlay: not valid individual amount");
            users[_winningUsers[index]].pendingPayments.himSelf += toDistribute;
            accumulatedAcademicExcellenceBonus -= toDistribute;
            emit BonusAvailableToCollectEvent(_winningUsers[index], users[_winningUsers[index]].id, 0, 4);
            emit AvailableBalanceForUser(_winningUsers[index], accumulatedAcademicExcellenceBonus/_winningUsers.length);
        }
        if(accumulatedAcademicExcellenceBonus > 0){
            administrativeBalance += accumulatedAcademicExcellenceBonus;
            emit AvailableAdministrativeBalance(accumulatedAcademicExcellenceBonus);
        }
    }
// End Region Career   

// Start Region Prosumer
    function payProsumerPlan() external {
        require( isActivatedMembership(msg.sender), "Prosumer: user is not active this month.");
        require( users[msg.sender].careerIsActive , "Prosumer: user is not active in Career Plan"); 
        require(!users[msg.sender].prosumerIsActive, "Prosumer: user is already active in Prosumer Plan");
        users[msg.sender].prosumerIsActive = true;
        // users[msg.sender].prosumerPlan.degree = 1;

        users[msg.sender].prosumerPlan.range = 1;
        users[msg.sender].balance += prosumerRangeConfig[users[msg.sender].prosumerPlan.range].directPayment;
        updateMembers(PROSUMER_ACTIVE_LEVEL, users[msg.sender].referrer, 3);

        depositToken.safeTransferFrom(msg.sender, address(this), prosumerPlanPrice);
        globalBalance += prosumerPlanPrice;
        
        administrativeBalance += 10e18; //TODO: REsto que queda del pago de activacion de un prosumer... meter en una variable
        emit AvailableAdministrativeBalance(10e18);//TODO: REsto que queda del pago de activacion de un prosumer... meter en una variable

        emit ProsumerPlan_NewProsumer(msg.sender, 1);
    }

    function setProsumerLevelByAdmin(address _userAddress, uint8 _degree) external restricted {
        require( isActivatedMembership(msg.sender), "Prosumer: user is not active this month."); 
        require(!users[msg.sender].prosumerIsActive, "Prosumer: user is already active in Prosumer Plan");
        require(_degree > 0, 'Prosumer: level no valid!!');
        users[_userAddress].prosumerInfo.degree = _degree;
        emit ProsumerPlan_SetProsumerLevelByAdmin(msg.sender, _userAddress, _degree);
    }
    
    // function buyCourse(uint _courseId) external {
    //     // (uint _courseCost) = prosumerContract.getTransferBalanceByCourse(_courseId, users[msg.sender].academicInfo.accumulatedDirectToSeeCourse);
    //     require(_courseCost > 0 , 'Prosumer: you do not have enough direct referrals');
    //     require(_courseCost <= users[msg.sender].academicInfo.coursePay, 'Prosumer: balance of user is not valid');        
    //     (address _prosumer, uint _courseGain, uint _moneyBox, uint _adminBonus, uint _himself, uint8 _level, uint8 _plan) = prosumerContract.buyCourse(_courseId, msg.sender);       
    //     setPendingPayments(_prosumer, _moneyBox, _adminBonus, (_himself + _courseGain), 0, _level, _plan);
    //     users[msg.sender].academicInfo.coursePay -= _courseCost;
    // }

    function getAccumulatedDirectToSeeCourse(address _userAddress) external view override(IBitacoraPlay) returns(uint){
        require(isUserExists(_userAddress), "BitacoraPlay: user is not Exist");
        return users[_userAddress].academicInfo.accumulatedDirectToSeeCourse;
    }
// End Region Prosumer

// Start Region Courses
    function setCourse(string calldata _courseId, address _prosumerAuthor, uint8 _cycle, uint _price, uint _amountToProsumer) external restricted returns(uint) {
        require(isUserExists(_prosumerAuthor), "Course: user is not exists. Register first.");
        require(users[_prosumerAuthor].prosumerIsActive, "Course: user is not a Prosumer");
        require(isActivatedMembership(_prosumerAuthor), "Course: user is not active this month.");
        require(_price > _amountToProsumer, 'Course: price and amountToProsumer no valid');
        require(_cycle <= degreePerCycleConfig[users[_prosumerAuthor].prosumerInfo.degree], "Course: this author does not make in this cycle");
        courses[courseId] = Course({
            id: courseId, 
            cycle: _cycle, 
            degree:users[_prosumerAuthor].prosumerInfo.degree,
            prosumerAuthor: _prosumerAuthor,
            extraPrice: _price,
            amountToProsumer: _amountToProsumer
        });
        emit Course_NewCourse(_courseId, courseId);        
        return courseId++;            
    }

// End Region Courses 

// Start Region Withdrawals
    function withdrawUserBonusByAdmin(uint _amount, address _user) external override restricted safeTransferAmount(_amount){
        require(0 < _amount, "BitacoraPlay: Invalid amount");
        require(isUserExists(_user), "BitacoraPlay: user is not Exist");
        require(_amount <= users[_user].pendingPayments.adminBonus, "BitacoraPlay: insufficient funds");
        depositToken.safeTransfer(msg.sender, _amount);
        globalBalance -= _amount;
        users[_user].pendingPayments.adminBonus -= _amount;
        emit AdminWithdrewUserBonus(msg.sender, _user, _amount);
    }

    // function witdrawUserFoundsOfReferredDirect() external {
    //     require(isUserExists(msg.sender), "BitacoraPlay: user is not exists");
    //     require(isActivatedMembership(msg.sender), "BitacoraPlay: has not paid monthly payment");
    //     require(0 < users[msg.sender].pendingPayments.referralDirectPayments, "BitacoraPlay: Invalid amount");
    //     require(users[msg.sender].pendingPayments.referralDirectPayments >= 100e18, "BitacoraPlay: insufficient funds");
    //     require(users[msg.sender].pendingPayments.referralDirectPayments <= globalBalance, "BitacoraPlay: insufficient funds");
    //     users[msg.sender].pendingPayments.referralDirectPayments = 0;
    //     depositToken.safeTransfer(msg.sender, users[msg.sender].pendingPayments.referralDirectPayments);
    //     globalBalance -= users[msg.sender].pendingPayments.referralDirectPayments;
    //     emit UserWithdrewFunds(msg.sender, users[msg.sender].pendingPayments.referralDirectPayments);
    // }

    function witdrawUserFounds(uint _amount) external override safeTransferAmount(_amount){
        require(isUserExists(msg.sender), "user is not exists");
        require(0 < _amount, "BitacoraPlay: Invalid amount");
        require(_amount <= users[msg.sender].pendingPayments.himSelf && _amount <= users[msg.sender].balance, "BitacoraPlay: insufficient funds");
        depositToken.safeTransfer(msg.sender, _amount);
        users[msg.sender].pendingPayments.himSelf -= _amount;
        users[msg.sender].balance -= _amount;
        globalBalance -= _amount;
        emit UserWithdrewFunds(msg.sender, _amount);
    }

    function userInvestmentInMoneyBox(uint _amount, uint8 _categoryId) external override safeTransferAmount(_amount){
        require(isUserExists(msg.sender), "user is not exists");
        require(50e18 < _amount, "BitacoraPlay: Invalid amount");//TODO: Verificar con oscar cual debe ser este valor
        require(_amount <= users[msg.sender].pendingPayments.moneyBox, "BitacoraPlay: insufficient funds");
        moneyBox.addToBalance( msg.sender, _amount);        
        users[msg.sender].pendingPayments.moneyBox -= _amount;
        depositToken.safeIncreaseAllowance(address(moneyBox), _amount);
        globalBalance -= _amount;
        emit UserInvestmentInMoneyBox(msg.sender, _categoryId, _amount);
    }
// End Region Withdrawals
}