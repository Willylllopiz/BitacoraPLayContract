pragma solidity ^0.6.2;
// SPDX-License-Identifier: MIT

import "./IMoneyBox.sol";
import "./ISettingsBasic.sol";
import "./SafeTRC20.sol";
import "./Prosumer.sol";
import "./BitacoraPlayBasic.sol";

contract BitacoraPlay is BitacoraPlayBasic {
    using SafeTRC20 for ITRC20;

    event SignUpEvent(address indexed _newUser, uint indexed _userId, address indexed _sponsor, uint _sponsorId);
    event CompletedBonusEvent(address indexed _user, uint _userId, uint8 indexed _range, uint8 indexed plan);
    event BonusAvailableToCollectEvent(address indexed _user, uint _userId, uint8 indexed _range, uint8 indexed plan);
    event NewUserChildEvent(address indexed _user, address indexed _sponsor);
    event AvailableBalanceForMoneyBox(address indexed _user, uint _amounnt);
    event AvailableAdministrativeBalance(uint _amounnt); 

    struct User {
        uint id;
        address wallet;
        address referrer;

        uint8 referRange;
        uint8 careerRange;
        ReferredPlan referredPlan;
        PendingBonus pendingBonus;

        uint256 activationDate;
    }

    struct ReferredPlan {
        uint accumulatedMembers; //Cantidad acumulada de pagos de hasta el quinto nivel
        uint accumulatedDirectMembers; //cantidad acumulada de referidos directos para uso de los bonos
        uint accumulatedPayments; //cantidad acumulada de pagos para la distribucion del bono actual del usuario      
        uint accumulatedDirectToSeeCourse;//Cantidad acumulada de referidos para ver Cursos
    }

     struct PendingBonus {
        uint moneyBox;
        uint adminBonus;
        uint himSelf;
    }

    struct ReferredRangeConfig {
        bool active;
        uint assetsDirect;
        uint assetsSameNetwork;
        uint8 qualifyingCycles;

        uint bonusValue;
        uint surplus;
        uint remainderVehicleBonus;
    }
    
    struct ReferredDistributionsPayments {
        uint referralDirectPayment; //60% of referralPlanPrice.
        uint referralBonus;
        uint careerPlanFiveLevel;
        uint carrerPlanBonus;
        uint coursePay;
        uint admin;
    }

    mapping(address => User) users;
    mapping(uint => address) internal idToAddress;    
    mapping(address => ReferredDistributionsPayments) userAvailablePayments;

    Prosumer prosumerContract;

    address public owner;
    address externalAddress;
    address rootAddress;

    uint public lastUserId = 2;
    uint public referralPlanPrice = 35e18;
        
    uint8 public constant ACTIVE_LEVEL = 5;

    ReferredDistributionsPayments referredDistributionsPaymentsConfig;
    mapping(uint8 => ReferredRangeConfig) internal referredRangeConfig;

    constructor(ITRC20 _depositTokenAddress, address _externalAddress, address _rootAddress, IMoneyBox _moneyBox, ISettingsBasic _settingsBasic, Prosumer _prosumerContract) public {
        _owner = msg.sender;
        _locked = false;
        depositToken = _depositTokenAddress;

        globalBalance = 0;
        administrativeBalance = 0;

        moneyBox = _moneyBox;
        prosumerContract = _prosumerContract;
        
        settingsBasic = _settingsBasic;
        // settingsBasic = _settingsBasic;

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

        referredDistributionsPaymentsConfig = ReferredDistributionsPayments({
            referralDirectPayment: 18e18, //60% of referralPlanPrice.
            referralBonus: 0.36e18,//0.36 * 5 = 1.8 referral bonus five level
            careerPlanFiveLevel: 3e18,
            carrerPlanBonus: 0.6e18,
            coursePay: 2.4e18,
            admin: 9.2e18 //Surplus to Admin
        });

        externalAddress = _externalAddress;
        rootAddress = _rootAddress;
        users[rootAddress].id = 1;
        users[rootAddress].referrer = address(0);
        idToAddress[1] = rootAddress;
        users[_rootAddress].referRange = 5;
        // users[_rootAddress].careerPlan.activeCareerPlan = true;
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

    function getReferrer(address _userAddress) public view returns(address){
        require(isUserExists(_userAddress) && _userAddress != rootAddress, 'user not valid');
        return users[_userAddress].referrer;
    }

    function isUserExists(address user) public view override returns (bool) {
        return (users[user].id != 0);
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
        users[userAddress].referRange = 0;//revisar si empieza en rookie o junior

        // users[userAddress].careerPlan.activeCareerPlan = false;

        lastUserId++;

        payMonth(userAddress);
        emit NewUserChildEvent(userAddress, referrerAddress);
        emit SignUpEvent(userAddress, users[userAddress].id, referrerAddress, users[referrerAddress].id);
        // repartir ganancias del plan carrera!!!!!!!!!!!!!
    }

    // Este metodo se debe verificar quien y como paga la inscripcion del nuevo usuario
    function signUpAdmin(address _user, address _sponsor) external restricted returns(string memory) {
        registration(_user, _sponsor);
        return "registration successful";
    }

    function signUp(address referrerAddress) external {
        // require(msg.value == referralPlanPrice, "invalid registration cost");
        registration(msg.sender, referrerAddress);
    }

    function payMonth(address _user) private {
        require(isUserExists(_user), "user is not exists. Register first.");
        depositToken.safeTransferFrom(_user, address(this), referralPlanPrice);
        users[_user].activationDate =  block.timestamp + 30 days;
        users[users[_user].referrer].referredPlan.accumulatedDirectMembers ++;
        prosumerContract.setAccumulatedDirectToSeeCourse(users[_user].referrer);
        userAvailablePayments[users[_user].referrer].coursePay += referredDistributionsPaymentsConfig.coursePay;
        updateActiveMembers(ACTIVE_LEVEL, users[_user].referrer);
        administrativeBalance += referredDistributionsPaymentsConfig.admin;
        // referredDistributionsPaymentsConfig.careerPlanFiveLevel;// TODO: Reparti esto con el plan carrera
        // referredDistributionsPaymentsConfig.carrerPlanBonus;//TODO: DAr Este bono
        emit AvailableAdministrativeBalance(5e18);
        globalBalance += referralPlanPrice;
    }

    function payMonthly() external {
        // require(msg.value == referralPlanPrice, "invalid price");//TODO: cambiar esta comprobacion para usdt
        require( isActivatedMembership(msg.sender), "user already active this month.");
        payMonth(msg.sender);
    }

    function updateActiveMembers(uint8 _level, address _referrerAddress) private {
        if(_level > 0 && _referrerAddress != rootAddress){
            users[_referrerAddress].referredPlan.accumulatedMembers ++;
            users[_referrerAddress].referredPlan.accumulatedPayments += referredDistributionsPaymentsConfig.referralBonus;
            if (checkRange(_referrerAddress, users[_referrerAddress].referRange)){
                emit CompletedBonusEvent(_referrerAddress, users[_referrerAddress].id, users[_referrerAddress].referRange, 0);
                changeRange(_referrerAddress);
            }
            updateActiveMembers(_level - 1, users[_referrerAddress].referrer);
        }
        return;
    }

    function isActivatedMembership(address _user) public view returns(bool) {
        require(isUserExists(_user), "user is not exists. Register first.");
        return block.timestamp <=  users[_user].activationDate;
    }   

    // Check that a user (_userAddress) is in a specified range (_range) in Referred Plan
    function checkRange(address _userAddress, uint8 _range) public view returns(bool) {
        return users[ _userAddress ].referredPlan.accumulatedMembers >= (referredRangeConfig[_range].assetsSameNetwork *
        referredRangeConfig[_range].qualifyingCycles ) &&
        users[ _userAddress ].referredPlan.accumulatedDirectMembers >= referredRangeConfig[_range].assetsDirect;
    }

    function changeRange(address userAddress) private {
        users[userAddress].referredPlan.accumulatedPayments -= referredRangeConfig[users[userAddress].referRange].bonusValue;
        if (users[userAddress].referRange == 1){
            users[userAddress].pendingBonus.moneyBox += referredRangeConfig[users[userAddress].referRange].bonusValue;
            emit AvailableBalanceForMoneyBox(userAddress, referredRangeConfig[users[userAddress].referRange].bonusValue);
        }
        else{
            users[userAddress].pendingBonus.adminBonus += referredRangeConfig[users[userAddress].referRange].bonusValue;
        }
        users[rootAddress].pendingBonus.himSelf += referredRangeConfig[users[userAddress].referRange].surplus;
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

    function buyCourse(uint _courseId) external {
        (uint _balnceTransfer) = prosumerContract.getTransferBalanceByCourse(_courseId, msg.sender);
        require(_balnceTransfer > 0 , 'you do not have enough direct referrals');
        require(_balnceTransfer <= userAvailablePayments[msg.sender].coursePay, 'balance not valid');//TODO: Verificar que tiene ese monto para comprar el curso!!!!!!
        // depositToken.safeTransfer(address(prosumerContract), _balnceTransfer);
        depositToken.safeIncreaseAllowance(address(prosumerContract), _balnceTransfer);
        prosumerContract.buyCourse(_courseId, msg.sender);
    }

    function withdrawUserBonusByAdmin(uint _amount, address _user) external override restricted safeTransferAmount(_amount){
        require(0 < _amount, "BitacoraPlay: Invalid amount");
        require(isUserExists(_user), "user is not Prosumer");
        require(_amount <= users[_user].pendingBonus.adminBonus, "BitacoraPlay: insufficient funds");
        depositToken.safeTransfer(msg.sender, _amount);
        globalBalance -= _amount;
        users[_user].pendingBonus.adminBonus -= _amount;
        emit AdminWithdrewUserBonus(msg.sender, _user, _amount);
    }

    function witdrawUserFounds(uint _amount) external override safeTransferAmount(_amount){
        require(isUserExists(msg.sender), "user is not Prosumer");
        require(0 < _amount, "BitacoraPlay: Invalid amount");
        require(_amount <= users[msg.sender].pendingBonus.himSelf, "BitacoraPlay: insufficient funds");
        depositToken.safeTransfer(msg.sender, _amount);
        users[msg.sender].pendingBonus.himSelf -= _amount;
        globalBalance -= _amount;
        emit UserWithdrewFunds(msg.sender, _amount);
    }

    function userInvestmentInMoneyBox(uint _amount, uint8 _categoryId) external override safeTransferAmount(_amount){
        require(isUserExists(msg.sender), "user is not exists");
        require(50e18 < _amount, "BitacoraPlay: Invalid amount");//TODO: Verificar con oscar cual debe ser este valor
        require(_amount <= users[msg.sender].pendingBonus.moneyBox, "BitacoraPlay: insufficient funds");
        depositToken.safeIncreaseAllowance(address(moneyBox), _amount);
        moneyBox.addToBalance( msg.sender, _amount);        
        users[msg.sender].pendingBonus.moneyBox -= _amount;
        globalBalance -= _amount;
        emit UserInvestmentInMoneyBox(msg.sender, _categoryId, _amount);
    }
}

//TODO: comprobar donde quiera que sea necesario que no es la raiz antes de cualquier operacion de indexacion!!!!