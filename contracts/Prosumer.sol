pragma solidity ^0.6.2;
// SPDX-License-Identifier: MIT

import "./BitacoraPlayBasic.sol";
import "./BitacoraPlay.sol";
import "./Career.sol";
import "./ISettingsBasic.sol";
import "./SafeTRC20.sol";

contract Prosumer is BitacoraPlayBasic{

    using SafeTRC20 for ITRC20;
    
    event Prosumer_NewProsumer(address indexed _user, uint8 _prosumerLevel);
    event Prosumer_CompletedBonusEvent(address indexed _user, uint _userId, uint8 indexed _range, uint8 indexed plan);
    event Prosumer_BonusAvailableToCollectEvent(address indexed _user, uint8 indexed _range, uint8 indexed plan); //Plan 2 es el bono por activacion del plan prosumer y el plan 3 es el bono por cantidad de cursos vistos 
    event Prosumer_AvailableBalanceForMoneyBox(address indexed _user, uint _amounnt);
    event Prosumer_AvailableBalanceForUser(address indexed _user, uint _amounnt);
    event Prosumer_AvailableAdministrativeBalance(uint _amounnt); 
    event Prosumer_SetProsumerLevelByAdmin(address indexed _admin, address indexed _user, uint8 _level);
    event Prosumer_AvailableCoursePaymentToProsumer(address indexed _prosumer, address indexed _user, uint _amount);

    struct User {
        bool isProsumer;
        uint accumulatedDirectToSeeCourse;
        uint8 prosumerLevel;
        uint8 prosumerBonusRange;
        uint accumulatedDirectPlanProsumer;

        uint8 cycle;
    }

    struct Course {
        uint id;
        uint8 cycle;
        uint8 prosumerLevel;
        address prosumerAuthor;
        uint purchases;

        uint extraPrice;
        uint amountToProsumer;
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

    struct CycleConfig {
        uint assetsDirect;
        uint amountToPay;
        uint promotionBonus;
    }

    struct ProsumerLevelConfig {     
        uint bonusValue;   
        uint surplus;         
    }

    mapping(uint => Course) courses;
    mapping(uint => mapping(address => bool)) courseXUsersViews;
    mapping(address => User) public users;
    mapping(address => PendingBonus) public pendingBonus;
    mapping(address => mapping(uint8 => mapping(uint8 => uint))) prosumerXLevelXCycleXViewsCount;
    
    
    mapping(uint8 => ProsumerRangeConfig) internal prosumerRangeConfig;    
    mapping(uint8 => mapping(uint8 => CycleConfig)) internal prosumerPerCycleConfig;
     mapping(uint8 => ProsumerLevelConfig) internal prosumerLevelConfig;
     mapping(uint8 => mapping(uint8 => uint)) viewsCycleConfig;

    BitacoraPlay bitacoraPlay;
    Career careerPlan;
    
    uint public prosumerPlanPrice = 50e18;
    uint public courseId = 1;   

    modifier onlyContractRestricted(){
        require(address(bitacoraPlay) != address(0), 'required BitacoraPlay address');
        require(address(bitacoraPlay) == msg.sender, 'only BytacoraPlay Contract');
        _;
    }

    constructor() public {               
        administrativeBalance = 0;
        globalBalance = 0;

        prosumerRangeConfig [1] = ProsumerRangeConfig({assetsDirect: 10, bonusValue: 300e18, surplus: 200e18});
        prosumerRangeConfig [2] = ProsumerRangeConfig({assetsDirect: 40, bonusValue: 900e18, surplus: 1100e18});
        prosumerRangeConfig [3] = ProsumerRangeConfig({assetsDirect: 10, bonusValue: 1200e18, surplus: 1300e18});

         // Prosumer Guia, Cycle 1 => number of assets direct in refered plan to be able to buy a course 
        prosumerPerCycleConfig[1][1] = CycleConfig({assetsDirect: 6, amountToPay:8e18, promotionBonus: 6.4e18});
        // Prosumer Teacher, Cycles 1,2,3 => number of assets direct in refered plan to be able to buy a course
        prosumerPerCycleConfig[2][1] = CycleConfig({assetsDirect: 7, amountToPay:10e18, promotionBonus: 6.8e18});
        prosumerPerCycleConfig[2][2] = CycleConfig({assetsDirect: 8, amountToPay:13e18, promotionBonus: 6.2e18});
        prosumerPerCycleConfig[2][3] = CycleConfig({assetsDirect: 10, amountToPay:15e18, promotionBonus: 9e18});
        // Prosumer Mentor, Cycles 1,2,3,4,5,6 => number of assets direct in refered plan to be able to buy a course
        prosumerPerCycleConfig[3][1] = CycleConfig({assetsDirect: 8, amountToPay:14e18, promotionBonus: 5.2e18});
        prosumerPerCycleConfig[3][2] = CycleConfig({assetsDirect: 9, amountToPay:16e18, promotionBonus: 5.6e18});
        prosumerPerCycleConfig[3][3] = CycleConfig({assetsDirect: 12, amountToPay:18e18, promotionBonus: 10.8e18});
        prosumerPerCycleConfig[3][4] = CycleConfig({assetsDirect: 15, amountToPay:20e18, promotionBonus: 16e18});
        prosumerPerCycleConfig[3][5] = CycleConfig({assetsDirect: 20, amountToPay:30e18, promotionBonus: 18e18});
        prosumerPerCycleConfig[3][6] = CycleConfig({assetsDirect: 30, amountToPay:22e18, promotionBonus: 50e18});

        // Prosumer Teacher BonusUp
        prosumerLevelConfig[1].bonusValue = 640e18;        
        prosumerLevelConfig[1].surplus = 0;
        viewsCycleConfig[1][1] = 100;
        // Prosumer Mentor BonusUp
        prosumerLevelConfig[2].bonusValue = 7000e18;
        prosumerLevelConfig[2].surplus = 720e18;
        viewsCycleConfig[2][1] = 200;
        viewsCycleConfig[2][2] = 300;
        viewsCycleConfig[2][3] = 500;
        // Prosumer Mentor Star BonusUp
        prosumerLevelConfig[3].bonusValue = 50000e18;
        prosumerLevelConfig[3].surplus = 1000e18;
        viewsCycleConfig[3][4] = 200;
        viewsCycleConfig[3][5] = 300;
        // Prosumer Mentor Top BonusUp
        prosumerLevelConfig[4].bonusValue = 100000e18;
        prosumerLevelConfig[4].surplus = 10000e18;
        viewsCycleConfig[4][6] = 500;

        _owner = msg.sender;
        _locked = true;
    }

    function initialize(ITRC20 _depositTokenAddress, BitacoraPlay _bitacoraPlay, Career _careerPlan, ISettingsBasic _settingsBasic) external onlyOwner{        
        depositToken = _depositTokenAddress; 
        bitacoraPlay = _bitacoraPlay;
        careerPlan = _careerPlan;
        settingsBasic = _settingsBasic;
        _locked = false;
    }

    function isUserExists(address _user) public view override returns (bool){
        return bitacoraPlay.isUserExists(_user);
    }

    function getTransferBalanceByCourse(uint _course, address _userAddress) public view returns(uint){
        if(users[_userAddress].accumulatedDirectToSeeCourse >= prosumerPerCycleConfig[courses[_course].prosumerLevel][courses[_course].cycle].assetsDirect){
            return prosumerPerCycleConfig[courses[_course].prosumerLevel][courses[_course].cycle].amountToPay +  prosumerPerCycleConfig[courses[_course].prosumerLevel][courses[_course].cycle].promotionBonus;
        }
        return 0;        
    }

    function setAccumulatedDirectToSeeCourse(address _user) external onlyContractRestricted {
        require(isUserExists(_user));
        users[_user].accumulatedDirectToSeeCourse++;
    }

    function getAccumulatedDirectToSeeCourse(address _user) public view returns(uint){
        return users[_user].accumulatedDirectToSeeCourse;
    }  
    
    // // Pay Prosumer plan From BitacoraPlay Contract 
    // function payProsumerPlan(address _userAddress, uint8 _prosumerLevel) external onlyContractRestricted {
    //     updateProsumerPlan(_userAddress, _prosumerLevel);
    //     depositToken.safeTransferFrom(msg.sender, address(this), prosumerPlanPrice);
    //     emit Prosumer_NewProsumer(_userAddress, _prosumerLevel);
    // }

    function setProsumerLevelByAdmin(address _userAddress, uint8 _prosumerLevel) external restricted {
        require(isProsumer(_userAddress), 'user is not a Prosumer!!');
        require(_prosumerLevel > 0, 'level no valid!!');
        users[_userAddress].prosumerLevel = _prosumerLevel;
        emit Prosumer_SetProsumerLevelByAdmin(msg.sender, _userAddress, _prosumerLevel);
    }

    // Pay Prosumer plan From external Address
    function payProsumerPlan() external {
        updateProsumerPlan(msg.sender, 1);
        depositToken.safeTransferFrom(msg.sender, address(this), prosumerPlanPrice);
        emit Prosumer_NewProsumer(msg.sender, 1);
    }

    function updateProsumerPlan(address _user, uint8 _prosumerLevel) internal {      
        require( bitacoraPlay.isActivatedMembership(_user), "user is not active this month.");
        require(careerPlan.isActivatedCareerPlan(_user), "user does not active in Career Plan"); 
        users[_user].isProsumer = true;
        users[_user].prosumerLevel = _prosumerLevel;
        users[_user].prosumerBonusRange = 1;
        address _referer = bitacoraPlay.getReferrer(_user);
        if( users[_referer].prosumerBonusRange <= 3) {
            users[_referer].accumulatedDirectPlanProsumer ++;
            if(users[_referer].accumulatedDirectPlanProsumer >= prosumerRangeConfig[users[_user].prosumerBonusRange].assetsDirect){
                users[_referer].accumulatedDirectPlanProsumer -= prosumerRangeConfig[users[_user].prosumerBonusRange].assetsDirect;
                pendingBonus[_referer].moneyBox += prosumerRangeConfig[users[_user].prosumerBonusRange].bonusValue;
                administrativeBalance += prosumerRangeConfig[users[_user].prosumerBonusRange].surplus;
                emit Prosumer_AvailableAdministrativeBalance(prosumerRangeConfig[users[_user].prosumerBonusRange].surplus);
                emit Prosumer_BonusAvailableToCollectEvent( _referer, users[_referer].prosumerBonusRange, 2);
                emit Prosumer_AvailableBalanceForMoneyBox(_referer, prosumerRangeConfig[users[_user].prosumerBonusRange].bonusValue);
                users[_referer].prosumerBonusRange ++;
            }
        }
        else{
            administrativeBalance += prosumerPlanPrice;
            emit Prosumer_AvailableAdministrativeBalance(prosumerPlanPrice);
        }
    }

    function isCourseExists(uint _course) public view returns (bool) {
        return (courses[_course].id != 0);
    }

    function isProsumer(address _userAddress) public view returns(bool){
        return users[_userAddress].isProsumer;
    }

    function setCourse(address _prosumerAuthor, uint8 _cycle, uint _price, uint _amountToProsumer) external restricted returns(uint) {
        require(bitacoraPlay.isActivatedMembership(_prosumerAuthor), "user is not active this month.");
        require(_price > _amountToProsumer, 'price and amountToProsumer no valid');
        courses[courseId] = Course({
            id: courseId, 
            cycle: _cycle, 
            prosumerLevel:users[_prosumerAuthor].prosumerLevel,
            prosumerAuthor: _prosumerAuthor,
            purchases: 0,
            extraPrice: _price,
            amountToProsumer: _amountToProsumer
        });
        courseId++;
        return courseId-1;            
    }   

    function buyCourseDirectByUser(uint _course, address _user, uint _amount) external {
        require(isCourseExists(_course), "Course is not exists");  
        require( bitacoraPlay.isActivatedMembership(_user), "user is not active this month.");
        require(!courseXUsersViews[_course][_user], 'User already saw this video');
        require(courses[_course].extraPrice <= _amount && _amount > 0, 'amount no valid');
        require(users[_user].cycle <= courses[_course].cycle, 'user cycle no valid');
        depositToken.safeTransferFrom(_user, address(this), _amount);
        globalBalance += _amount;
        pendingBonus[courses[_course].prosumerAuthor].himSelf += courses[_course].extraPrice;
        administrativeBalance += _amount - courses[_course].extraPrice;
        emit Prosumer_AvailableAdministrativeBalance(_amount - courses[_course].extraPrice);
        emit Prosumer_AvailableBalanceForUser(_user, courses[_course].extraPrice);

    }

    function buyCourse(uint _course, address _user) external onlyContractRestricted {            
        require(isCourseExists(_course), "Course is not exists");  
        require( bitacoraPlay.isActivatedMembership(_user), "user is not active this month.");
        require(users[_user].cycle <= courses[_course].cycle, 'user cycle no valid');
        require(users[_user].accumulatedDirectToSeeCourse >= prosumerPerCycleConfig[courses[_course].prosumerLevel][courses[_course].cycle].assetsDirect, "user is not ready to watch this video");
        require(!courseXUsersViews[_course][_user], 'User already saw this video');
        depositToken.safeTransferFrom(msg.sender, address(this), prosumerPerCycleConfig[courses[_course].prosumerLevel][courses[_course].cycle].amountToPay + prosumerPerCycleConfig[courses[_course].prosumerLevel][courses[_course].cycle].promotionBonus);

        courseXUsersViews[_course][_user] = true;
        prosumerXLevelXCycleXViewsCount[courses[_course].prosumerAuthor][courses[_course].prosumerLevel][courses[_course].cycle]++;//deberia aumentar el valor que se va acumulando para el bono tambien (_promotionBonus)?
        pendingBonus[courses[_course].prosumerAuthor].himSelf += prosumerPerCycleConfig[courses[_course].prosumerLevel][courses[_course].cycle].amountToPay;
        emit Prosumer_AvailableCoursePaymentToProsumer(courses[_course].prosumerAuthor,  msg.sender, prosumerPerCycleConfig[courses[_course].prosumerLevel][courses[_course].cycle].amountToPay);
        
        checkAndUpdateProsumerLevel(courses[_course].prosumerAuthor);

        globalBalance += prosumerPerCycleConfig[courses[_course].prosumerLevel][courses[_course].cycle].amountToPay + prosumerPerCycleConfig[courses[_course].prosumerLevel][courses[_course].cycle].promotionBonus;
    }

    function checkAndUpdateProsumerLevel(address _prosumer) internal {
        require(isProsumer(_prosumer), 'user is not a Prosumer');
        if(users[_prosumer].prosumerLevel == 1 && 
        viewsCycleConfig[users[_prosumer].prosumerLevel][1] >= prosumerXLevelXCycleXViewsCount[_prosumer][users[_prosumer].prosumerLevel][1]){
            setBonus(_prosumer, prosumerLevelConfig[users[_prosumer].prosumerLevel].bonusValue, prosumerLevelConfig[users[_prosumer].prosumerLevel].surplus, 0, 3);
            users[_prosumer].prosumerLevel++;
            return;
        }
        if(users[_prosumer].prosumerLevel == 2 && 
        viewsCycleConfig[2][1] >= prosumerXLevelXCycleXViewsCount[_prosumer][2][1] &&
        viewsCycleConfig[2][2] >= prosumerXLevelXCycleXViewsCount[_prosumer][2][2] &&
        viewsCycleConfig[2][3] >= prosumerXLevelXCycleXViewsCount[_prosumer][2][3] ){
            setBonus(_prosumer, 0, prosumerLevelConfig[users[_prosumer].prosumerLevel].surplus, prosumerLevelConfig[users[_prosumer].prosumerLevel].bonusValue, 3);
            users[_prosumer].prosumerLevel++;
            return;
        }
        if(users[_prosumer].prosumerLevel == 3 && 
        viewsCycleConfig[3][4] >= prosumerXLevelXCycleXViewsCount[_prosumer][3][4] &&
        viewsCycleConfig[3][5] >= prosumerXLevelXCycleXViewsCount[_prosumer][3][5]){
            setBonus(_prosumer, 0, prosumerLevelConfig[users[_prosumer].prosumerLevel].surplus, prosumerLevelConfig[users[_prosumer].prosumerLevel].bonusValue, 3);
            users[_prosumer].prosumerLevel++;
            return;
        }
        
        if(users[_prosumer].prosumerLevel == 4 && 
        viewsCycleConfig[4][6] >= prosumerXLevelXCycleXViewsCount[_prosumer][4][6] ){
            setBonus(_prosumer, 0, prosumerLevelConfig[users[_prosumer].prosumerLevel].surplus, prosumerLevelConfig[users[_prosumer].prosumerLevel].bonusValue, 3);
            users[_prosumer].prosumerLevel++;
            return;
        }
    }

    function setBonus(address _user, uint _moneyBox, uint _adminBonus, uint _himself, uint8 _plan) internal {
        if(_moneyBox > 0){
            pendingBonus[_user].moneyBox += _moneyBox;
            emit Prosumer_AvailableBalanceForMoneyBox(_user, _moneyBox);
        }
        if(_adminBonus > 0){
            administrativeBalance += _adminBonus;
            emit Prosumer_AvailableAdministrativeBalance(_adminBonus);
        }
        if(_himself > 0){
            pendingBonus[_user].himSelf += _himself;
            emit Prosumer_AvailableBalanceForUser(_user, _himself);
        }                   
        emit Prosumer_BonusAvailableToCollectEvent(_user, users[_user].prosumerLevel, _plan);
    }

    function withdrawUserBonusByAdmin(uint _amount, address _user) external override restricted safeTransferAmount(_amount){
        require(0 < _amount, "BitacoraPlay: Invalid amount");
        require(isProsumer(_user) && isUserExists(_user), "user is not Prosumer");
        require(_amount <= pendingBonus[_user].adminBonus, "BitacoraPlay: insufficient funds");
        depositToken.safeTransfer(msg.sender, _amount);
        pendingBonus[_user].adminBonus -= _amount;
        globalBalance -= _amount;
        emit AdminWithdrewUserBonus(msg.sender, _user, _amount);
    }

    function witdrawUserFounds(uint _amount) external override safeTransferAmount(_amount){
        require(isProsumer(msg.sender) && isUserExists(msg.sender), "user is not Prosumer");
        require(0 < _amount, "BitacoraPlay: Invalid amount");
        require(_amount <= pendingBonus[msg.sender].himSelf, "BitacoraPlay: insufficient funds");
        depositToken.safeTransfer(msg.sender, _amount);
        pendingBonus[msg.sender].himSelf -= _amount;
        globalBalance -= _amount;
        emit UserWithdrewFunds(msg.sender, _amount);
    }

    function userInvestmentInMoneyBox(uint _amount, uint8 _categoryId) external override safeTransferAmount(_amount){
        require(isProsumer(msg.sender) && isUserExists(msg.sender), "user is not exists");
        require(50e18 < _amount, "BitacoraPlay: Invalid amount");//TODO: Verificar con oscar cual debe ser este valor
        require(_amount <= pendingBonus[msg.sender].moneyBox, "BitacoraPlay: insufficient funds");
        depositToken.safeIncreaseAllowance(address(moneyBox), _amount);
        moneyBox.addToBalance( msg.sender, _amount);        
        pendingBonus[msg.sender].moneyBox -= _amount;
        globalBalance -= _amount;
        emit UserInvestmentInMoneyBox(msg.sender, _categoryId, _amount);
    }

}