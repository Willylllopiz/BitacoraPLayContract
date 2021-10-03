pragma solidity ^0.6.2;
// SPDX-License-Identifier: MIT

// import "./BitacoraPlayBasic.sol";
import "./IBitacoraPlay.sol";
// import "./Career.sol";
import "./ISettingsBasic.sol";
// import "./IProsumer.sol";
import "./SafeTRC20.sol";

contract Prosumer{

    using SafeTRC20 for ITRC20;
    // event Prosumer_NewCourse(string indexed _courseId, uint _contractCourseId);
    event Prosumer_NewProsumer(address indexed _user, uint8 _degree);
    event Prosumer_BonusAvailableToCollectEvent(address indexed _user, uint8 indexed _range, uint8 indexed plan); //Plan 2 es el bono por activacion del plan prosumer y el plan 3 es el bono por cantidad de cursos vistos 
    event Prosumer_AvailableBalanceForMoneyBox(address indexed _user, uint _amounnt);
    event Prosumer_AvailableBalanceForUser(address indexed _user, uint _amounnt);
    event Prosumer_AvailableAdministrativeBalance(uint _amounnt); 
    // event Prosumer_SetProsumerDegreeByAdmin(address indexed _admin, address indexed _user, uint8 _degree);
    event Prosumer_AvailableCoursePaymentToProsumer(address indexed _prosumer, address indexed _user, uint _amount);

    struct ProsumerInfo {
        bool isActive;
        // uint accumulatedDirectPlanProsumer;
        // uint8 prosumerBonusRange;

        uint8 degree;
        PendingBonus pendingBonus;
    }

    // struct Course {
    //     uint id;
    //     uint8 cycle;
    //     uint8 degree;
    //     address prosumerAuthor;

    //     uint extraPrice;
    //     uint amountToProsumer;
    //     mapping(address => bool) usersViews;
    // }

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

    struct CycleConfig {
        uint assetsDirect;
        uint amountToPay;
        uint promotionBonus;
    }

    struct ProsumerDegreeConfig {     
        uint bonusValue;   
        uint surplus;         
    }

    // mapping(uint => Course) public courses;
    mapping(address => ProsumerInfo) prosumers;
    mapping(address => mapping(uint8 => mapping(uint8 => uint))) prosumerXDegreeXCycleXViewsCount;
    
    
    // mapping(uint8 => ProsumerRangeConfig) internal prosumerRangeConfig;    
    // mapping(uint8 => mapping(uint8 => CycleConfig)) internal degreeCycleXAccumullatesToSee;
    // mapping(uint8 => ProsumerDegreeConfig) internal degreeConfig;
    // mapping(uint8 => mapping(uint8 => uint)) viewsCycleConfig;
    // mapping(uint8 => uint8) degreePerCycleConfig;

    IBitacoraPlay bitacoraPlay;
    // Career careerPlan;
    
    // uint public prosumerPlanPrice = 50e18;
    uint public courseId = 1;  
    uint public prosumerBonusRangeCount; 

    modifier onlyContractRestricted(){
        require(address(msg.sender) != address(0), 'Prosumer, required BitacoraPlay address');
        require(address(bitacoraPlay) == msg.sender, 'Prosumer only BitacoraPlay Contract');
        _;
    }

    // constructor() public {               
    //     administrativeBalance = 0;
    //     globalBalance = 0;       

    //     _owner = msg.sender;
    //     _locked = true;
    // }

    // function initialize(ITRC20 _depositTokenAddress, IBitacoraPlay _bitacoraPlay, /*Career _careerPlan,*/ ISettingsBasic _settingsBasic) external {        
    //     depositToken = _depositTokenAddress; 
    //     bitacoraPlay = _bitacoraPlay;
    //     // careerPlan = _careerPlan;
    //     settingsBasic = _settingsBasic;

    //     // prosumerBonusRangeCount = 3;
    //     // prosumerRangeConfig [1] = ProsumerRangeConfig({assetsDirect: 10, bonusValue: 300e18, surplus: 200e18});
    //     // prosumerRangeConfig [2] = ProsumerRangeConfig({assetsDirect: 40, bonusValue: 900e18, surplus: 1100e18});
    //     // prosumerRangeConfig [3] = ProsumerRangeConfig({assetsDirect: 10, bonusValue: 1200e18, surplus: 1300e18});

    //     //  // [Prosumer degree, number of Cycle 1]  => number of assets direct in refered plan to be able to buy a course 
    //     // degreeCycleXAccumullatesToSee[1][1] = CycleConfig({assetsDirect: 6, amountToPay:8e18, promotionBonus: 6.4e18});
    //     // degreeCycleXAccumullatesToSee[2][1] = CycleConfig({assetsDirect: 7, amountToPay:10e18, promotionBonus: 6.8e18});
    //     // degreeCycleXAccumullatesToSee[2][2] = CycleConfig({assetsDirect: 8, amountToPay:13e18, promotionBonus: 6.2e18});
    //     // degreeCycleXAccumullatesToSee[2][3] = CycleConfig({assetsDirect: 10, amountToPay:15e18, promotionBonus: 9e18});
    //     // degreeCycleXAccumullatesToSee[3][1] = CycleConfig({assetsDirect: 8, amountToPay:14e18, promotionBonus: 5.2e18});
    //     // degreeCycleXAccumullatesToSee[3][2] = CycleConfig({assetsDirect: 9, amountToPay:16e18, promotionBonus: 5.6e18});
    //     // degreeCycleXAccumullatesToSee[3][3] = CycleConfig({assetsDirect: 12, amountToPay:18e18, promotionBonus: 10.8e18});
    //     // degreeCycleXAccumullatesToSee[3][4] = CycleConfig({assetsDirect: 15, amountToPay:20e18, promotionBonus: 16e18});
    //     // degreeCycleXAccumullatesToSee[3][5] = CycleConfig({assetsDirect: 20, amountToPay:30e18, promotionBonus: 18e18});
    //     // degreeCycleXAccumullatesToSee[3][6] = CycleConfig({assetsDirect: 30, amountToPay:22e18, promotionBonus: 50e18});

    //     // // Prosumer Teacher BonusUp
    //     // degreeConfig[1].bonusValue = 640e18;        
    //     // degreeConfig[1].surplus = 0;
    //     // viewsCycleConfig[1][1] = 100;
    //     // // Prosumer Mentor BonusUp
    //     // degreeConfig[2].bonusValue = 7000e18;
    //     // degreeConfig[2].surplus = 720e18;
    //     // viewsCycleConfig[2][1] = 200;
    //     // viewsCycleConfig[2][2] = 300;
    //     // viewsCycleConfig[2][3] = 500;
    //     // // Prosumer Mentor Star BonusUp
    //     // degreeConfig[3].bonusValue = 50000e18;
    //     // degreeConfig[3].surplus = 1000e18;
    //     // viewsCycleConfig[3][4] = 200;
    //     // viewsCycleConfig[3][5] = 300;
    //     // // Prosumer Mentor Top BonusUp
    //     // degreeConfig[4].bonusValue = 100000e18;
    //     // degreeConfig[4].surplus = 10000e18;
    //     // viewsCycleConfig[4][6] = 500;

    //     // degreePerCycleConfig[1] = 1;
    //     // degreePerCycleConfig[2] = 3;
    //     // degreePerCycleConfig[3] = 6;

    //     _locked = false;
    // }

    // function isUserExists(address _user) public view override returns (bool){
    //     return bitacoraPlay.isUserExists(_user);
    // } 

// Start Region Prosumer Activation
    // function setProsumerDegreeByAdmin(address _userAddress, uint8 _degree) external restricted {
    //     require(isActiveProsumer(_userAddress), 'Prosumer: is not a Prosumer!!');
    //     require(_degree > 0, 'Prosumer: degree no valid!!');
    //     prosumers[_userAddress].degree = _degree;
    //     emit Prosumer_SetProsumerDegreeByAdmin(msg.sender, _userAddress, _degree);
    // }

    // function payProsumerPlan() external {
    //     require( bitacoraPlay.isActivatedMembership(msg.sender), "Prosumer: user is not active this month.");
    //     // require(careerPlan.isActive(msg.sender), "Prosumer: user is not active in Career Plan"); 
    //     require(!isActiveProsumer(msg.sender), "Prosumer: user is already active in Prosumer Plan");
    //     prosumers[msg.sender].isActive = true;
    //     prosumers[msg.sender].degree = 1;
    //     prosumers[msg.sender].prosumerBonusRange = 1;
    //     updateProsumerPlan(msg.sender);
    //     depositToken.safeTransferFrom(msg.sender, address(this), prosumerPlanPrice);
    //     emit Prosumer_NewProsumer(msg.sender, 1);
    // }

    // function updateProsumerPlan(address _user) internal {  
    //     address _referrerAddress = bitacoraPlay.getReferrer(_user);
    //     ProsumerInfo storage _referer = prosumers[_referrerAddress];
    //     if( _referer.prosumerBonusRange <= prosumerBonusRangeCount) {
    //         _referer.accumulatedDirectPlanProsumer ++;
    //         if(_referer.accumulatedDirectPlanProsumer >= prosumerRangeConfig[prosumers[_user].prosumerBonusRange].assetsDirect){
    //             _referer.accumulatedDirectPlanProsumer -= prosumerRangeConfig[prosumers[_user].prosumerBonusRange].assetsDirect;
    //             _referer.pendingBonus.moneyBox += prosumerRangeConfig[prosumers[_user].prosumerBonusRange].bonusValue;
    //             administrativeBalance += prosumerRangeConfig[prosumers[_user].prosumerBonusRange].surplus;
    //             emit Prosumer_AvailableAdministrativeBalance(prosumerRangeConfig[prosumers[_user].prosumerBonusRange].surplus);
    //             emit Prosumer_BonusAvailableToCollectEvent( _referrerAddress, _referer.prosumerBonusRange, 2);
    //             emit Prosumer_AvailableBalanceForMoneyBox(_referrerAddress, prosumerRangeConfig[prosumers[_user].prosumerBonusRange].bonusValue);
    //             _referer.prosumerBonusRange ++;
    //         }
    //     }
    //     else{
    //         administrativeBalance += prosumerPlanPrice;
    //         emit Prosumer_AvailableAdministrativeBalance(prosumerPlanPrice);
    //     }
    // }
// End Region Prosumer Activation

// Start Region Courses    
    // function setCourse(string calldata _courseId, address _prosumerAuthor, uint8 _cycle, uint _price, uint _amountToProsumer) external restricted returns(uint) {
    //     require(isActiveProsumer(_prosumerAuthor), "Course: user is not a Prosumer");
    //     require(bitacoraPlay.isActivatedMembership(_prosumerAuthor), "Course: user is not active this month.");
    //     require(_price > _amountToProsumer, 'Course: price and amountToProsumer no valid');
    //     require(_cycle <= degreePerCycleConfig[prosumers[_prosumerAuthor].degree], "Course: this author does not make in this cycle");
    //     courses[courseId] = Course({
    //         id: courseId, 
    //         cycle: _cycle, 
    //         degree:prosumers[_prosumerAuthor].degree,
    //         prosumerAuthor: _prosumerAuthor,
    //         purchases: 0,
    //         extraPrice: _price,
    //         amountToProsumer: _amountToProsumer
    //     });
    //     emit Prosumer_NewCourse(_courseId, courseId);        
    //     return courseId++;            
    // }  

    // function getTransferBalanceByCourse(uint _course, uint _accumulatedDirectToSeeCourse) public view override(IProsumer) returns(uint){
    //     if(_accumulatedDirectToSeeCourse >= degreeCycleXAccumullatesToSee[courses[_course].degree][courses[_course].cycle].assetsDirect){
    //         return degreeCycleXAccumullatesToSee[courses[_course].degree][courses[_course].cycle].amountToPay +  degreeCycleXAccumullatesToSee[courses[_course].degree][courses[_course].cycle].promotionBonus;
    //     }
    //     return 0;        
    // }

    // function isCourseExists(uint _course) public view returns (bool) {
    //     return (courses[_course].id != 0);
    // }

    // function isActiveProsumer(address _userAddress) public view returns(bool){
    //     return prosumers[_userAddress].isActive;
    // }


    // function buyCourseDirectlyByUser(uint _courseId, address _user, uint _amount) external {
    //     require(isCourseExists(_courseId), "Courses: course is not exists");  
    //     require( bitacoraPlay.isActivatedMembership(_user), "Courses: user is not active this month.");
    //     // require(careerPlan.isActive(msg.sender), "Prosumer: user is not active in Career Plan"); 
    //     require(!courses[_courseId].usersViews[_user], 'Courses: User already saw this video');
    //     require(courses[_courseId].extraPrice <= _amount && _amount > 0, 'Courses: amount no valid');
    //     // require(prosumers[_user].cycle <= courses[_courseId].cycle, 'Courses: user cycle no valid');
    //     depositToken.safeTransferFrom(_user, address(this), _amount);
    //     globalBalance += _amount;
    //     prosumers[courses[_courseId].prosumerAuthor].pendingBonus.himSelf += courses[_courseId].amountToProsumer;
    //     administrativeBalance += _amount - courses[_courseId].amountToProsumer;
    //     emit Prosumer_AvailableAdministrativeBalance(_amount - courses[_courseId].amountToProsumer);
    //     emit Prosumer_AvailableBalanceForUser(courses[_courseId].prosumerAuthor, courses[_courseId].amountToProsumer);

    // }

    // function buyCourse(uint _courseId, address _user) external override(IProsumer) onlyContractRestricted returns(address, uint, uint, uint, uint, uint8, uint8){            
    //     require(isCourseExists(_courseId), "Courses: course is not exists");  
    //     require( bitacoraPlay.isActivatedMembership(_user), "Courses: user is not active this month.");  
    //     // require(careerPlan.isActive(msg.sender), "Prosumer: user is not active in Career Plan");      
    //     // require(prosumers[_user].cycle <= courses[_courseId].cycle, 'Courses: user cycle no valid');
    //     Course storage _course = courses[_courseId];
    //     // require(prosumers[_user].cycle <= _course.cycle, 'Courses: user cycle is not valid');
    //     require(bitacoraPlay.getAccumulatedDirectToSeeCourse(_user) >= 
    //         degreeCycleXAccumullatesToSee[_course.degree][_course.cycle].assetsDirect, 
    //         "Courses: user is not ready to watch this video");
    //     require(!_course.usersViews[_user], 'Courses: User already saw this video');
           
    //    //Mark course viewed by user  
    //     _course.usersViews[_user] = true;
    //     //Number of views of a course per cycle of a user
    //     prosumerXDegreeXCycleXViewsCount[_course.prosumerAuthor][_course.degree][_course.cycle]++;//deberia aumentar el valor que se va acumulando para el bono tambien (_promotionBonus)?
    //     // 
    //     (uint _moneyBox, uint _adminBonus, uint _himself, uint8 _degree, uint8 _plan) = checkAndUpdateProsumerDegree(_course.prosumerAuthor);
    //     emit Prosumer_AvailableCoursePaymentToProsumer(_course.prosumerAuthor,  msg.sender, degreeCycleXAccumullatesToSee[_course.degree][_course.cycle].amountToPay);
    //     return (_course.prosumerAuthor, degreeCycleXAccumullatesToSee[_course.degree][_course.cycle].amountToPay, _moneyBox, _adminBonus, _himself, _degree, _plan);
    // }

    // function checkAndUpdateProsumerDegree(address _prosumer) internal returns(uint, uint, uint, uint8, uint8){
    //     require(isActiveProsumer(_prosumer), 'Prosumer: user is not a Prosumer');
    //     ProsumerInfo storage prosumer = prosumers[_prosumer];
    //     if(prosumer.degree == 1 && 
    //     viewsCycleConfig[prosumer.degree][1] >= prosumerXDegreeXCycleXViewsCount[_prosumer][prosumer.degree][1]){
    //         prosumer.degree++;
    //         return (degreeConfig[prosumer.degree].bonusValue, degreeConfig[prosumer.degree].surplus, 0, prosumer.degree-1, 3);
    //     }
    //     if(prosumer.degree == 2 && 
    //     viewsCycleConfig[2][1] >= prosumerXDegreeXCycleXViewsCount[_prosumer][2][1] &&
    //     viewsCycleConfig[2][2] >= prosumerXDegreeXCycleXViewsCount[_prosumer][2][2] &&
    //     viewsCycleConfig[2][3] >= prosumerXDegreeXCycleXViewsCount[_prosumer][2][3] ){
    //         prosumer.degree++;
    //         return (0, degreeConfig[prosumer.degree].surplus, degreeConfig[prosumer.degree].bonusValue, prosumer.degree-1, 3);
    //     }
    //     if(prosumer.degree == 3 && 
    //     viewsCycleConfig[3][4] >= prosumerXDegreeXCycleXViewsCount[_prosumer][3][4] &&
    //     viewsCycleConfig[3][5] >= prosumerXDegreeXCycleXViewsCount[_prosumer][3][5]){
    //         prosumer.degree++;
    //         return (0, degreeConfig[prosumer.degree].surplus, degreeConfig[prosumer.degree].bonusValue, prosumer.degree-1, 3);
    //     }        
    //     if(prosumer.degree == 4 && 
    //     viewsCycleConfig[4][6] >= prosumerXDegreeXCycleXViewsCount[_prosumer][4][6] ){
    //         prosumer.degree++;
    //         return (0, degreeConfig[prosumer.degree].surplus, degreeConfig[prosumer.degree].bonusValue, prosumer.degree-1, 3);
    //     }
    //     return (0,0,0,0,0);
    // }
}