pragma solidity ^0.6.2;
// SPDX-License-Identifier: MIT

// import "./BitacoraPlayBasic.sol";
// import "./ISettingsBasic.sol";
// import "./IBitacoraPlay.sol";
// import "./BitacoraSettings.sol";

// contract BitacoraPlay is BitacoraPlayBasic, IBitacoraPlay {
//     event SignUpEvent(address indexed _newUser, uint indexed _userId, address indexed _sponsor, uint _sponsorId);
//     // Plan: 1 => ReferredBonus, Plan: 1 => CareerRangeBonus, Plan: 2 => ProsumerRangeBonus, Plan: 3 => ProsumerLevelBonus, Plan:4 AcademicExcellence
//     event BonusAvailableToCollectEvent(address indexed _user, uint _userId, uint8 indexed _range, uint8 indexed plan);
//     event AccumulatedAcademicExcellenceBonus(uint _amount);

//     event NewUserChildEvent(address indexed _user, address indexed _sponsor);
//     event AvailableBalanceForMoneyBox(address indexed _user, uint _amount);
//     event AvailableAdministrativeBalance(uint _amonnt);
//     event AvailableBalanceForUser(address indexed _user, uint _amount); 
//     event AvailableReferralDirectPayments(address indexed _user, uint _amount);  
//     event AvailableAdministrativeBalanceForUserBonus(address indexed _user, uint _amount);
//     event CareerPlan_Royalties(address indexed _user, uint amount, uint8 _userLevel);    
//     event ProsumerPlan_NewProsumer(address indexed _user, uint8 _prosumerLevel);    
//     event ProsumerPlan_SetProsumerLevelByAdmin(address indexed _admin, address indexed _user, uint8 _level);

//     event Course_NewCourse(string indexed _courseId);
//     event UserBoughtCourse(string indexed _courseId, address indexed _user, uint _price);
//     event UserBoughtDirectlyCourse(string indexed _courseId, address indexed _user, uint _amountUser, uint _amountProsumer);
//     event UserCycleIncresed(address indexed _user, uint cycle);
//     event UserApprovedThisCourse(string indexed _courseId_courseId, address indexed _user);

//     struct User {
//         uint id;
//         address referrer;        
//         uint balance; 

//         bool careerIsActive;
//         bool prosumerIsActive;
//         BasicPlan referredPlan;
//         BasicPlan careerPlan;
//         BasicPlan prosumerPlan;

//         PendingPayments pendingPayments;
//         AcademicInfo academicInfo;
//         ProsumerInfo prosumerInfo;
//         uint256 activationDate;
//     }

//     struct BasicPlan {        
//         uint8 range;
//         uint accumulatedIndirectMembers; 
//         uint accumulatedDirectMembers;    
//     }

//     struct ProsumerInfo {
//         uint8 degree;
//         uint8 cycle;
//         mapping(uint8 => mapping(uint8 => uint)) degreeXCycleXViewsCount;
//     }

//     struct AcademicInfo{
//         uint accumulatedDirectToSeeCourse;
//         uint accumulatedCoursePay; 
//         uint8 cycle;
//     }

//     struct PendingPayments {
//         uint moneyBox;
//         uint adminBonus;
//         uint himSelf;
//         uint careerPlanRoyalties;
//         uint referralDirectPayments;
//     }

//     struct Course {
//         string id;
//         uint8 cycle;
//         uint8 degree;
//         address prosumerAuthor;

//         uint extraPrice;
//         uint amountToProsumer;
//         mapping(address => UserCourse) userCourse;
//     }

//     struct UserCourse{
//             bool bought;
//             bool approved;
//     }

    

//     struct BasicRangeConfig{
//         uint assetsDirect;
//         uint directPayment;
//         uint assetsIndirect;
//         uint indirectPayment;
//         uint moneyBox;
//         uint adminBonus;
//         uint himSelf;
//         uint surplus;
//     }

//     struct ReferredDistributionsPayments {
//         uint referralDirectPayment; //60% of referralPlanPrice.
//         uint referralBonus;
//         uint careerPlanBonus;
//         uint coursePaymentReferral;
//         uint admin;
//     }        

//     struct CycleConfig {
//         uint assetsDirect;
//         uint coursePaymentByCycle;
//         uint promotionBonus;
//     }

//     struct ProsumerDegreeConfig {     
//         uint moneyBox;   
//         uint surplus;         
//     }

//     mapping(address => User) users;
//     mapping(uint => address) internal idToAddress; 

//     mapping(string => Course) public courses;

//     address externalAddress;
//     address rootAddress;

//     uint public lastUserId = 2; 
//     uint public referralPlanPrice = 35e18;
//     uint public careerPlanPrice = 50e18;
//     uint public prosumerPlanPrice = 50e18;
//     uint8 public constant REFERRED_ACTIVE_LEVEL = 5;
//     uint8 public constant CAREER_ACTIVE_LEVEL = 5;
//     uint8 public constant PROSUMER_ACTIVE_LEVEL = 1;
//     uint public accumulatedAcademicExcellenceBonus;    
//     uint8 public cycleCount;    

//     ReferredDistributionsPayments referredDistributionsPaymentsConfig;
//     uint [] careerPlanRoyaltiesConfig;
//     // mapping(uint8 => BasicRangeConfig) internal referredRangeConfig;
//     // uint8 referredRangeCountConfig;
//     // mapping(uint8 => BasicRangeConfig) internal careerRangeConfig;
//     // uint careerRangeCountConfig;
//     // mapping(uint8 => BasicRangeConfig) internal prosumerRangeConfig;
//     // uint prosumerRangeCountConfig;
//     mapping(uint8 => uint8) degreePerCycleConfig;
//     mapping(uint8 => mapping(uint8 => CycleConfig)) internal degreeCycleXAccumullatesToSeeConfig;    
//     mapping(uint8 => ProsumerDegreeConfig) internal degreeConfig;
//     mapping(uint8 => mapping(uint8 => uint)) viewsCycleConfig;

//     BitacoraSettings bitacoraSettings;

//     constructor(address _externalAddress, address _rootAddress) public {
//         globalBalance = 0;
//         administrativeBalance = 0;   
//         accumulatedAcademicExcellenceBonus = 0;

//         externalAddress = _externalAddress;
//         rootAddress = _rootAddress;
//         users[rootAddress].id = 1;
//         users[rootAddress].referrer = address(0);
//         idToAddress[1] = rootAddress;
//         users[_rootAddress].referredPlan.range = 5;

//         _owner = msg.sender;
//         _locked = true;
//     }

//     function initialize(ITRC20 _depositTokenAddress, IMoneyBox _moneyBox, ISettingsBasic _settingsBasic, BitacoraSettings _bitacoraSettings) external onlyOwner{        
//         depositToken = _depositTokenAddress;
//         moneyBox = _moneyBox;
//         settingsBasic = _settingsBasic;
//         bitacoraSettings = _bitacoraSettings;

//         referredDistributionsPaymentsConfig = ReferredDistributionsPayments({
//             referralDirectPayment: 18e18, //60% of referralPlanPrice.
//             referralBonus: 0.36e18,//0.36 * 5 = 1.8 referral bonus five level
//             careerPlanBonus: 0.6e18,
//             coursePaymentReferral: 2.4e18,
//             admin: 9.2e18 //Surplus to Admin
//         });  

//         // referredRangeCountConfig = 4;
//         // // The rookie bonus setup is unnecessary, it is not registered yet
//         // referredRangeConfig [1] = BasicRangeConfig({
//         //     assetsDirect: 30,
//         //     assetsIndirect: 3000,
//         //     directPayment: 18e18, //60% of referralPlanPrice.
//         //     indirectPayment: 0.36e18,//0.36 * 5 = 1.8 referral bonus five level
//         //     moneyBox: 500e18,    
//         //     adminBonus:0,
//         //     himSelf:0,      
//         //     surplus: 40e18
//         // });
//         // // Leader Bonus Configuration
//         // referredRangeConfig[2] = BasicRangeConfig({
//         //     assetsDirect: 100,
//         //     assetsIndirect: 14000,
//         //     directPayment: 18e18, //60% of referralPlanPrice.
//         //     indirectPayment: 0.36e18,//0.36 * 5 = 1.8 referral bonus five level
//         //     moneyBox: 0,
//         //     adminBonus: 1800e18,
//         //     himSelf: 0,
//         //     surplus: 0
//         // });
//         // // Guru Bonus Configuration
//         // referredRangeConfig[3] = BasicRangeConfig({
//         //     assetsDirect: 300,
//         //     assetsIndirect: 40000,
//         //     directPayment: 18e18, //60% of referralPlanPrice.
//         //     indirectPayment: 0.36e18,//0.36 * 5 = 1.8 referral bonus five level
//         //     moneyBox: 0,
//         //     adminBonus: 4500e18,
//         //     himSelf: 0,
//         //     surplus: 0
//         // });
//         // // GuruVehicle Bonus Configuration
//         // referredRangeConfig[4] = BasicRangeConfig({
//         //     assetsDirect: 300,
//         //     assetsIndirect: 40000,
//         //     directPayment: 18e18, //60% of referralPlanPrice.
//         //     indirectPayment: 0.36e18,//0.36 * 5 = 1.8 referral bonus five level
//         //     moneyBox: 0,
//         //     adminBonus: 28080e18,
//         //     himSelf: 0,
//         //     surplus: 0
//         // });      
        
//         // Career Plan Five Level Royalties: 3e18
//         careerPlanRoyaltiesConfig[4] = 0.3e18;
//         careerPlanRoyaltiesConfig[3] = 0.6e18;
//         careerPlanRoyaltiesConfig[2] = 0.9e18;
//         careerPlanRoyaltiesConfig[1] = 1.2e18;

//         // careerRangeCountConfig = 4;
//         // careerRangeConfig [1] = BasicRangeConfig({
//         //     assetsDirect: 30, 
//         //     directPayment: 25e18,
//         //     assetsIndirect: 0, 
//         //     indirectPayment: 0,
//         //     moneyBox: 0,
//         //     adminBonus: 750e18,
//         //     himSelf: 0,
//         //     surplus:0
//         // });
//         // careerRangeConfig [2] = BasicRangeConfig({
//         //     assetsDirect: 70, 
//         //     directPayment: 25e18,
//         //     assetsIndirect: 0, 
//         //     indirectPayment: 0,
//         //     moneyBox: 0,
//         //     adminBonus: 1750e18,
//         //     himSelf: 0,  
//         //     surplus:0
//         // });
//         // careerRangeConfig [3] = BasicRangeConfig({
//         //     assetsDirect: 0,
//         //     directPayment: 0,
//         //     assetsIndirect: 1000, 
//         //     indirectPayment: 1e18,
//         //     moneyBox: 1800e18, 
//         //     adminBonus: 0,
//         //     himSelf: 0,
//         //     surplus:0
//         // });
//         // careerRangeConfig [4] = BasicRangeConfig({
//         //     assetsDirect: 0, 
//         //     directPayment: 0,
//         //     assetsIndirect: 5000, 
//         //     indirectPayment: 2e18,
//         //     moneyBox: 7200e18,  
//         //     adminBonus: 0,
//         //     himSelf: 0,
//         //     surplus:0
//         // });

//         // prosumerRangeCountConfig = 3;
//         // prosumerRangeConfig [1] = BasicRangeConfig({ 
//         //     assetsDirect: 10, 
//         //     directPayment: 40e18,
//         //     assetsIndirect: 0, 
//         //     indirectPayment: 0,
//         //     moneyBox: 300e18,  
//         //     adminBonus: 0,
//         //     himSelf: 0,
//         //     surplus:200e18
//         // });
//         // prosumerRangeConfig [2] = BasicRangeConfig({
//         //     assetsDirect: 40, 
//         //     directPayment: 40e18,
//         //     assetsIndirect: 0, 
//         //     indirectPayment: 0,
//         //     moneyBox: 900e18,  
//         //     adminBonus: 0,
//         //     himSelf: 0,
//         //     surplus:1100e18
//         // });
//         // prosumerRangeConfig [3] = BasicRangeConfig({
//         //     assetsDirect: 10,   
//         //     directPayment: 40e18,
//         //     assetsIndirect: 0, 
//         //     indirectPayment: 0,
//         //     moneyBox: 1200e18,  
//         //     adminBonus: 0,
//         //     himSelf: 0,
//         //     surplus:1300e18            
//         // });

//         cycleCount = 6;
//         degreePerCycleConfig[1] = 1;
//         degreePerCycleConfig[2] = 3;
//         degreePerCycleConfig[3] = 6;

//          // [Prosumer degree, number of Cycle 1]  => number of assets direct in refered plan to be able to buy a course 
//         degreeCycleXAccumullatesToSeeConfig[1][1] = CycleConfig({assetsDirect: 6, coursePaymentByCycle:8e18, promotionBonus: 6.4e18});
//         degreeCycleXAccumullatesToSeeConfig[2][1] = CycleConfig({assetsDirect: 7, coursePaymentByCycle:10e18, promotionBonus: 6.8e18});
//         degreeCycleXAccumullatesToSeeConfig[2][2] = CycleConfig({assetsDirect: 8, coursePaymentByCycle:13e18, promotionBonus: 6.2e18});
//         degreeCycleXAccumullatesToSeeConfig[2][3] = CycleConfig({assetsDirect: 10, coursePaymentByCycle:15e18, promotionBonus: 9e18});
//         degreeCycleXAccumullatesToSeeConfig[3][1] = CycleConfig({assetsDirect: 8, coursePaymentByCycle:14e18, promotionBonus: 5.2e18});
//         degreeCycleXAccumullatesToSeeConfig[3][2] = CycleConfig({assetsDirect: 9, coursePaymentByCycle:16e18, promotionBonus: 5.6e18});
//         degreeCycleXAccumullatesToSeeConfig[3][3] = CycleConfig({assetsDirect: 12, coursePaymentByCycle:18e18, promotionBonus: 10.8e18});
//         degreeCycleXAccumullatesToSeeConfig[3][4] = CycleConfig({assetsDirect: 15, coursePaymentByCycle:20e18, promotionBonus: 16e18});
//         degreeCycleXAccumullatesToSeeConfig[3][5] = CycleConfig({assetsDirect: 20, coursePaymentByCycle:30e18, promotionBonus: 18e18});
//         degreeCycleXAccumullatesToSeeConfig[3][6] = CycleConfig({assetsDirect: 30, coursePaymentByCycle:22e18, promotionBonus: 50e18});

//          // Prosumer Teacher BonusUp
//         degreeConfig[1].moneyBox = 640e18;        
//         degreeConfig[1].surplus = 0;
//         viewsCycleConfig[1][1] = 100;
//         // Prosumer Mentor BonusUp
//         degreeConfig[2].moneyBox = 7000e18;
//         degreeConfig[2].surplus = 720e18;
//         viewsCycleConfig[2][1] = 200;
//         viewsCycleConfig[2][2] = 300;
//         viewsCycleConfig[2][3] = 500;
//         // Prosumer Mentor Star BonusUp
//         degreeConfig[3].moneyBox = 50000e18;
//         degreeConfig[3].surplus = 1000e18;
//         viewsCycleConfig[3][4] = 200;
//         viewsCycleConfig[3][5] = 300;
//         // Prosumer Mentor Top BonusUp
//         degreeConfig[4].moneyBox = 100000e18;
//         degreeConfig[4].surplus = 10000e18;
//         viewsCycleConfig[4][6] = 500;

//         _locked = false;
//     }

//     fallback() external {
//         if(msg.data.length == 0) {
//             return registration(msg.sender, rootAddress);
//         }
//         registration(msg.sender, bytesToAddress(msg.data));
//     }

//     function bytesToAddress(bytes memory bys) private pure returns (address addr) {
//         assembly {
//             addr := mload(add(bys, 20))
//         }
//     }  

//     function setPendingPayments(address _user, uint _moneyBox, uint _adminBonus, uint _himself, uint _adminBalance,uint8 _level, uint8 _plan) internal {
//         if(_moneyBox > 0){
//             users[_user].pendingPayments.moneyBox += _moneyBox;
//             emit AvailableBalanceForMoneyBox(_user, _moneyBox);
//         }
//         if(_adminBonus > 0){
//             users[_user].pendingPayments.adminBonus += _adminBonus;//TODO: homogenizar esto para todos los planes
//             emit AvailableAdministrativeBalanceForUserBonus(_user, _adminBonus);
//         }
//         if(_himself > 0){
//             users[_user].pendingPayments.himSelf += _himself;
//             emit AvailableBalanceForUser(_user, _himself);
//         }
//         if(_adminBalance > 0){
//             administrativeBalance += _adminBalance;
//             emit AvailableAdministrativeBalance(_adminBalance);
//         }
//         if(_plan != 0 ){
//             emit BonusAvailableToCollectEvent(_user, users[_user].id, _level, _plan);  
//         }              
//     }  

//     function getPendingPayments(address _user) public view returns(uint, uint, uint, uint){
//         return (
//             users[_user].pendingPayments.moneyBox,
//             users[_user].pendingPayments.himSelf,
//             users[_user].pendingPayments.adminBonus,
//             users[_user].pendingPayments.careerPlanRoyalties
//         );
//     }

//     function getReferrer(address _userAddress) public view override returns(address){
//         require(isUserExists(_userAddress) && _userAddress != rootAddress, 'user not valid');
//         return users[_userAddress].referrer;
//     }

//     function isUserExists(address user) public view override(IBitacoraPlay, BitacoraPlayBasic) returns (bool) {
//         return (users[user].id != 0);
//     }    

//     function isActivatedMembership(address _user) public view override returns(bool) {
//         require(isUserExists(_user), "BitacoraPlay: user is not exists. Register first.");
//         return block.timestamp <=  users[_user].activationDate;
//     }

//     function signUp(address _referrerAddress) external returns(string memory){        
//         registration(msg.sender, _referrerAddress);        
//         return "registration successful!!";
//     }

//     function registration(address userAddress, address referrerAddress) private {
//         require(!isUserExists(userAddress), "user exists");
//         require(isUserExists(referrerAddress), "referrer not exists");

//         uint32 size;
//         assembly {
//             size := extcodesize(userAddress)
//         }
//         require(size == 0, "cannot be a contract");

//         idToAddress[lastUserId] = userAddress;
//         users[userAddress].id = lastUserId;
//         users[userAddress].referrer = referrerAddress;
//         users[userAddress].referredPlan.range = 1;//revisar si empieza en rookie o junior   
//         lastUserId++;

//         payMonth(userAddress);
//         emit NewUserChildEvent(userAddress, referrerAddress);
//         emit SignUpEvent(userAddress, users[userAddress].id, referrerAddress, users[referrerAddress].id);
//     }   

//     function payMonthly() external {
//         require( !isActivatedMembership(msg.sender), "user already active this month.");
//         payMonth(msg.sender);
//     }

//     function payMonth(address _user) private {
//         require(isUserExists(_user), "BitacoraPlay: user is not exists. Register first.");
//         depositToken.safeTransferFrom(_user, address(this), referralPlanPrice);
//         globalBalance += referralPlanPrice;
//         users[_user].activationDate =  block.timestamp + 30 days;

//         User storage _sponsorInfo = users[users[_user].referrer];
//         _sponsorInfo.referredPlan.accumulatedDirectMembers ++;
//         _sponsorInfo.balance += bitacoraSettings.referredRangeConfig(_sponsorInfo.referredPlan.range).directPayment;
//         _sponsorInfo.pendingPayments.referralDirectPayments += referredDistributionsPaymentsConfig.referralDirectPayment; 
//         emit AvailableReferralDirectPayments(users[_user].referrer, referredDistributionsPaymentsConfig.referralDirectPayment);    
//         _sponsorInfo.academicInfo.accumulatedDirectToSeeCourse ++;
//         _sponsorInfo.academicInfo.accumulatedCoursePay += referredDistributionsPaymentsConfig.coursePaymentReferral;

//         accumulatedAcademicExcellenceBonus += referredDistributionsPaymentsConfig.careerPlanBonus;
       
//         updateMembers(REFERRED_ACTIVE_LEVEL, users[_user].referrer, 1);
//         updateCareerPlanRoyalties(1, users[_user].referrer);

//         administrativeBalance += referredDistributionsPaymentsConfig.admin;
//         emit AvailableAdministrativeBalance(referredDistributionsPaymentsConfig.admin);
//     }     

//     function updateMembers(uint _level, address _userAddress, uint8 _plan) internal {
//         if(_level > 0){
//             (BasicPlan storage _basicPlan, BasicRangeConfig storage _config, uint _rangeCountConfig) = 
//                 _plan == 1 ?
//                     (users[_userAddress].referredPlan, bitacoraSettings.referredRangeConfig[users[_userAddress].referredPlan.range], bitacoraSettings.referredRangeCountConfig) 
//                     : _plan == 2 
//                         ? (users[_userAddress].careerPlan, bitacoraSettings.careerRangeConfig[users[_userAddress].careerPlan.range], bitacoraSettings.careerRangeCountConfig) 
//                         : (users[_userAddress].prosumerPlan, bitacoraSettings.prosumerRangeConfig[users[_userAddress].prosumerPlan.range], bitacoraSettings.prosumerRangeCountConfig);
//             if(_userAddress != rootAddress){
//                 _basicPlan.accumulatedIndirectMembers ++;

//                 if(_basicPlan.range <= _rangeCountConfig){
//                     users[_userAddress].balance += _config.indirectPayment;                                    
//                     if (_basicPlan.range <= _rangeCountConfig 
//                     ? _basicPlan.accumulatedIndirectMembers >= (_config.assetsIndirect) 
//                     && _basicPlan.accumulatedDirectMembers >= _config.assetsDirect 
//                     : false){
//                         require(users[_userAddress].balance >= 
//                             (_config.moneyBox 
//                                 + _config.adminBonus 
//                                 + _config.himSelf 
//                                 + _config.surplus
//                             ),
//                             "BitacoraPlay: Invalid Bonus Payment"
//                         );
//                         setPendingPayments(
//                             _userAddress, 
//                             _config.moneyBox, 
//                             _config.adminBonus, 
//                             _config.himSelf, 
//                             _config.surplus,
//                             _basicPlan.range, 
//                             1                        
//                         );
//                         // Updating Range 
//                         _basicPlan.range ++;
//                         _basicPlan.accumulatedIndirectMembers -= (_config.assetsIndirect );
//                         _basicPlan.accumulatedDirectMembers -= _config.assetsDirect;
//                         users[_userAddress].balance -= _config.moneyBox + _config.adminBonus + _config.himSelf + _config.surplus;
//                     }                   
//                 }
//                 else{
//                     administrativeBalance += _config.indirectPayment;
//                     emit AvailableAdministrativeBalance(_config.indirectPayment);
//                 }
//                 updateMembers(_level - 1, users[_userAddress].referrer, _plan);
//             }
//             else{
//                 administrativeBalance += _config.indirectPayment * _level;
//                 emit AvailableAdministrativeBalance(_config.indirectPayment * _level);
//             }
//         }
//         return;
//     }

// // Start Region Career
//     function payCareerPlanActivation(address _user) private {
//         require(isUserExists(_user), "BitacoraPlay: user is not exists. Register first.");
//         require(isActivatedMembership(_user), "BitacoraPlay: has not paid monthly payment");
//         require(!users[_user].careerIsActive, "Career: user is already active in career plan");
//         depositToken.safeTransferFrom(_user, address(this), careerPlanPrice);
//         globalBalance += careerPlanPrice;

//         users[_user].careerIsActive = true;
//         users[_user].careerPlan.range = 1;
//         users[_user].academicInfo.cycle = 1;

//         User storage _sponsor = users[users[_user].referrer];
//         _sponsor.careerPlan.accumulatedDirectMembers ++;
//         _sponsor.balance += bitacoraSettings.careerRangeConfig[_sponsor.careerPlan.range].directPayment;
//         updateMembers(CAREER_ACTIVE_LEVEL, users[_user].referrer, 2);
        
//         administrativeBalance +=10e18;
//         emit AvailableAdministrativeBalance(10e18);
//     }    

//     function updateCareerPlanRoyalties(uint8 _level, address _referrerAddress) private{
//         if(_level > 0 && _level < careerPlanRoyaltiesConfig.length-1){
//             if(_referrerAddress != rootAddress && users[_referrerAddress].careerIsActive && isActivatedMembership(_referrerAddress)){
//                 users[_referrerAddress].pendingPayments.careerPlanRoyalties += careerPlanRoyaltiesConfig[_level];
//                 emit CareerPlan_Royalties(_referrerAddress, careerPlanRoyaltiesConfig[_level], _level);
//             }
//             else{
//                 administrativeBalance += careerPlanRoyaltiesConfig[_level];
//                 emit AvailableAdministrativeBalance(careerPlanRoyaltiesConfig[_level]);
//             }
//             updateCareerPlanRoyalties(_level + 1, users[_referrerAddress].referrer);
//         }
//         return;
//     }
        
//     // Distribute the academic excellence bonus to a list of users !!!
//     function setUsersAcademicExcellenceBonus( address[] memory _winningUsers) public restricted{
//         require(_winningUsers.length  > 0, "BitacoraPlay: empty list");
//         require(accumulatedAcademicExcellenceBonus/_winningUsers.length  > 0, "BitacoraPlay: not valid individual amount");
//         uint toDistribute = accumulatedAcademicExcellenceBonus/_winningUsers.length;
//         for (uint256 index = 0; index < _winningUsers.length; index++) {
//             require(isUserExists(_winningUsers[index]), "BitacoraPlay: user is not exists.");
//             require(accumulatedAcademicExcellenceBonus > toDistribute, "BitacoraPlay: not valid individual amount");
//             users[_winningUsers[index]].pendingPayments.himSelf += toDistribute;
//             accumulatedAcademicExcellenceBonus -= toDistribute;
//             emit BonusAvailableToCollectEvent(_winningUsers[index], users[_winningUsers[index]].id, 0, 4);
//             emit AvailableBalanceForUser(_winningUsers[index], accumulatedAcademicExcellenceBonus/_winningUsers.length);
//         }
//         if(accumulatedAcademicExcellenceBonus > 0){
//             administrativeBalance += accumulatedAcademicExcellenceBonus;
//             emit AvailableAdministrativeBalance(accumulatedAcademicExcellenceBonus);
//         }
//     }
// // End Region Career   

// // Start Region Prosumer
//     function payProsumerPlan() external {
//         require( isActivatedMembership(msg.sender), "Prosumer: user is not active this month.");
//         require( users[msg.sender].careerIsActive , "Prosumer: user is not active in Career Plan"); 
//         require(!users[msg.sender].prosumerIsActive, "Prosumer: user is already active in Prosumer Plan");
//         users[msg.sender].prosumerIsActive = true;
//         // users[msg.sender].prosumerPlan.degree = 1;

//         users[msg.sender].prosumerPlan.range = 1;
//         users[msg.sender].balance += bitacoraSettings.prosumerRangeConfig[users[msg.sender].prosumerPlan.range].directPayment;
//         updateMembers(PROSUMER_ACTIVE_LEVEL, users[msg.sender].referrer, 3);

//         depositToken.safeTransferFrom(msg.sender, address(this), prosumerPlanPrice);
//         globalBalance += prosumerPlanPrice;
        
//         administrativeBalance += 10e18; //TODO: REsto que queda del pago de activacion de un prosumer... meter en una variable
//         emit AvailableAdministrativeBalance(10e18);//TODO: REsto que queda del pago de activacion de un prosumer... meter en una variable

//         emit ProsumerPlan_NewProsumer(msg.sender, 1);
//     }

//     function setProsumerLevelByAdmin(address _userAddress, uint8 _degree) external restricted {
//         require( isActivatedMembership(msg.sender), "Prosumer: user is not active this month."); 
//         require(!users[msg.sender].prosumerIsActive, "Prosumer: user is already active in Prosumer Plan");
//         require(_degree > 0, 'Prosumer: level no valid!!');
//         users[_userAddress].prosumerInfo.degree = _degree;
//         emit ProsumerPlan_SetProsumerLevelByAdmin(msg.sender, _userAddress, _degree);
//     }
// // End Region Prosumer

// // Start Region Courses
//     function setCourse(string calldata _courseId, address _prosumerAuthor, uint8 _cycle, uint _price, uint _amountToProsumer) external restricted returns(uint) {
//         require(isUserExists(_prosumerAuthor), "Course: user is not exists. Register first.");
//         require(users[_prosumerAuthor].prosumerIsActive, "Course: user is not a Prosumer");
//         require(isActivatedMembership(_prosumerAuthor), "Course: user is not active this month.");
//         require(_price > _amountToProsumer, 'Course: price and amountToProsumer no valid');
//         require(_cycle <= degreePerCycleConfig[users[_prosumerAuthor].prosumerInfo.degree], "Course: this author does not make in this cycle");
//         courses[_courseId] = Course({
//             id: _courseId, 
//             cycle: _cycle, 
//             degree:users[_prosumerAuthor].prosumerInfo.degree,
//             prosumerAuthor: _prosumerAuthor,
//             extraPrice: _price,
//             amountToProsumer: _amountToProsumer
//         });
//         emit Course_NewCourse(_courseId);              
//     }

//     function setUserApprovedCourse(string calldata _courseId, address _user) external restricted{        
//         require(isUserExists(_user), "Course: user is not Exist");
//         Course storage _course = courses[_courseId];
//         require(keccak256(abi.encodePacked(_course.id)) != keccak256(abi.encodePacked("")), "Courses: course is not exists");
//         require(_course.userCourse[_user].bought, 'Courses: User has not buy this video.');
//         require(!_course.userCourse[_user].approved,'Courses: User already approved this video.');
//         if(users[_user].academicInfo.cycle < cycleCount){
//             users[_user].academicInfo.cycle++;
//             emit UserCycleIncresed(_user, users[_user].academicInfo.cycle);
//         }
//         _course.userCourse[_user].approved = true;
//         emit UserApprovedThisCourse(_courseId, _user);
//     }

//     function buyCourse(string calldata _courseId, address _user) external{                    
//         require(isActivatedMembership(_user), "Courses: user is not active this month.");  
//         require(users[msg.sender].careerIsActive, "Course: user is not active in Career Plan");      
//         Course storage _course = courses[_courseId];
//         require(keccak256(abi.encodePacked(_course.id)) != keccak256(abi.encodePacked("")), "Courses: course is not exists");  
//         require(users[_user].academicInfo.cycle <= _course.cycle, 'Courses: user cycle no valid');
//         require(!_course.userCourse[_user].bought , 'Courses: User already bought  this video');
//         require(users[_user].academicInfo.accumulatedDirectToSeeCourse >= 
//             degreeCycleXAccumullatesToSeeConfig[_course.degree][_course.cycle].assetsDirect, 
//             "Courses: user is not ready to watch this video");
//         require(users[_user].academicInfo.accumulatedCoursePay >= degreeCycleXAccumullatesToSeeConfig[_course.degree][_course.cycle]. coursePaymentByCycle);
           
//        //Mark course viewed by user  
//         _course.userCourse[_user].bought  = true;
//         //Number of views of a course per cycle of a user
//         users[_course.prosumerAuthor].prosumerInfo.degreeXCycleXViewsCount[_course.degree][_course.cycle]++;//deberia aumentar el valor que se va acumulando para el bono tambien (_promotionBonus)?
//         // If the course grade is the same as the author's, check and update Prosumer bonus
//         if(_course.degree == users[_course.prosumerAuthor].prosumerInfo.degree){
//             checkAndUpdateProsumerDegree(_course.prosumerAuthor);
//         }
//         emit UserBoughtCourse(_courseId,  msg.sender, degreeCycleXAccumullatesToSeeConfig[_course.degree][_course.cycle].coursePaymentByCycle);
//     }

//     function checkAndUpdateProsumerDegree(address _prosumer) internal returns(bool){
//         ProsumerInfo storage _proInfo = users[_prosumer].prosumerInfo;
//         for (uint8 index = 1; index <= cycleCount; index++) {//TODO:Duda oscar si all se inicializa  en 0.....
//             if(_proInfo.degreeXCycleXViewsCount[_proInfo.degree][index] < viewsCycleConfig[_proInfo.degree][index]){
//                 return false;
//             }
//         }
//         setPendingPayments(_prosumer, degreeConfig[_proInfo.degree].moneyBox, 0, 0, degreeConfig[_proInfo.degree].surplus, _proInfo.degree, 3);
//         _proInfo.degree++;
//         return true;     
//     }

//     function buyCourseDirectlyByUser(string calldata _courseId, address _user, uint _amount) external {
//         require(keccak256(abi.encodePacked(courses[_courseId].id)) != keccak256(abi.encodePacked("")), "Courses: course is not exists");  
//         require(isActivatedMembership(_user), "Courses: user is not active this month."); 
//         require(users[msg.sender].careerIsActive, "Course: user is not active in Career Plan");  
//         Course storage _course = courses[_courseId];
//         require(!_course.userCourse[_user].bought , 'Courses: User already saw this video');
//         require(_course.extraPrice <= _amount && _amount > 0, 'Courses: amount no valid');  
//         require(users[_user].academicInfo.cycle <= _course.cycle, 'Courses: user cycle no valid');
//         depositToken.safeTransferFrom(_user, address(this), _amount);
//         globalBalance += _amount;
//         setPendingPayments(_course.prosumerAuthor, 0, 0, _course.amountToProsumer,  _amount - _course.amountToProsumer, 0, 0);
//         emit UserBoughtDirectlyCourse(_courseId, _user,  _course.amountToProsumer,  _amount - _course.amountToProsumer);
//     }

// // End Region Courses 

// // Start Region Withdrawals
//     function withdrawUserBonusByAdmin(uint _amount, address _user) external override restricted safeTransferAmount(_amount){
//         require(0 < _amount, "BitacoraPlay: Invalid amount");
//         require(isUserExists(_user), "BitacoraPlay: user is not Exist");
//         require(_amount <= users[_user].pendingPayments.adminBonus, "BitacoraPlay: insufficient funds");
//         depositToken.safeTransfer(msg.sender, _amount);
//         globalBalance -= _amount;
//         users[_user].pendingPayments.adminBonus -= _amount;
//         emit AdminWithdrewUserBonus(msg.sender, _user, _amount);
//     }

//     function witdrawUserFoundsOfReferredDirect() external {
//         require(isUserExists(msg.sender), "BitacoraPlay: user is not exists");
//         require(isActivatedMembership(msg.sender), "BitacoraPlay: has not paid monthly payment");
//         require(0 < users[msg.sender].pendingPayments.referralDirectPayments, "BitacoraPlay: Invalid amount");
//         require(users[msg.sender].pendingPayments.referralDirectPayments >= 100e18, "BitacoraPlay: insufficient funds");
//         require(users[msg.sender].pendingPayments.referralDirectPayments <= globalBalance, "BitacoraPlay: insufficient funds");
//         depositToken.safeTransfer(msg.sender, users[msg.sender].pendingPayments.referralDirectPayments);
//         globalBalance -= users[msg.sender].pendingPayments.referralDirectPayments;
//         emit UserWithdrewFunds(msg.sender, users[msg.sender].pendingPayments.referralDirectPayments);
//         users[msg.sender].pendingPayments.referralDirectPayments = 0;
//     }

//     function witdrawUserFounds(uint _amount) external override safeTransferAmount(_amount){
//         require(isUserExists(msg.sender), "user is not exists");
//         require(0 < _amount, "BitacoraPlay: Invalid amount");
//         require(_amount <= users[msg.sender].pendingPayments.himSelf && _amount <= users[msg.sender].balance, "BitacoraPlay: insufficient funds");
//         depositToken.safeTransfer(msg.sender, _amount);
//         users[msg.sender].pendingPayments.himSelf -= _amount;
//         users[msg.sender].balance -= _amount;
//         globalBalance -= _amount;
//         emit UserWithdrewFunds(msg.sender, _amount);
//     }

//     function userInvestmentInMoneyBox(uint _amount, uint8 _categoryId) external override safeTransferAmount(_amount){
//         require(isUserExists(msg.sender), "user is not exists");
//         require(50e18 < _amount, "BitacoraPlay: Invalid amount");//TODO: Verificar con oscar cual debe ser este valor
//         require(_amount <= users[msg.sender].pendingPayments.moneyBox, "BitacoraPlay: insufficient funds");
//         moneyBox.addToBalance( msg.sender, _amount);        
//         users[msg.sender].pendingPayments.moneyBox -= _amount;
//         depositToken.safeIncreaseAllowance(address(moneyBox), _amount);
//         globalBalance -= _amount;
//         emit UserInvestmentInMoneyBox(msg.sender, _categoryId, _amount);
//     }
// // End Region Withdrawals
// }