pragma solidity ^0.6.2;
// SPDX-License-Identifier: MIT

import "./IMoneyBox.sol";
import "./BitacoraPlayBasic.sol";
import "./BitacoraPlaySettings.sol";

contract BitacoraPlay is BitacoraPlayBasic {
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
        // uint8 cycle;
        // uint8 prosumerRange;
        // uint8 prosumerLevel;

        ReferredPlan referredPlan;
        PendingBonus pendingBonus;
        // CareerPlan careerPlan;
        // ProsumerPlan prosumerPlan;

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

    mapping(address => User) users;
    mapping(uint => address) internal idToAddress;

    constructor(ITRC20 _depositTokenAddress, address _externalAddress, address _rootAddress, IMoneyBox _moneyBox, BitacoraPlaySettings _bitacoraPlaySettings) public {
        owner = msg.sender;
        depositToken = _depositTokenAddress;

        moneyBox = _moneyBox;
        bitacoraPlaySettings = _bitacoraPlaySettings;

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

    function isUserExists(address user) public view returns (bool) {
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
        users[users[_user].referrer].referredPlan.accumulatedDirectToSeeCourse ++; //save accumulated to pay courses aqui debo llamar al metodo del contrato prosumer para que umente los referidos de un estudiante 
        updateActiveMembers(ACTIVE_LEVEL, users[_user].referrer);
        administrativeBalance +=5e18;
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
            users[_referrerAddress].referredPlan.accumulatedPayments += 0.36e18;
            if (checkRange(_referrerAddress, users[_referrerAddress].referRange)){
                emit CompletedBonusEvent(_referrerAddress, users[_referrerAddress].id, users[_referrerAddress].referRange, 0);
                changeRange(_referrerAddress);
            }
            updateActiveMembers(_level - 1, users[_referrerAddress].referrer);
        }
        return;
    }

    function isActivatedMembership(address user) public view returns(bool) {
        return block.timestamp <=  users[user].activationDate;
    }   

    // Check that a user (_userAddress) is in a specified range (_range) in Referred Plan
    function checkRange(address _userAddress, uint8 _range) public view returns(bool) {
        (uint _assetsDirect, uint _assetsSameNetwork, uint8 _qualifyingCycles, , , ) = bitacoraPlaySettings.getReferredConfigInfo(_range);
        return users[ _userAddress ].referredPlan.accumulatedMembers >= (_assetsSameNetwork *
        _qualifyingCycles ) &&
        users[ _userAddress ].referredPlan.accumulatedDirectMembers >= _assetsDirect;
    }

    function changeRange(address userAddress) private {
        (uint _assetsDirect, uint _assetsSameNetwork, , uint _bonusValue, uint _surplus, ) = bitacoraPlaySettings.getReferredConfigInfo(users[userAddress].referRange);
        users[userAddress].referredPlan.accumulatedPayments -= _bonusValue;
        if (users[userAddress].referRange == 1){
            users[userAddress].pendingBonus.moneyBox += _bonusValue;
            emit AvailableBalanceForMoneyBox(userAddress, _bonusValue);
        }
        else{
            users[userAddress].pendingBonus.adminBonus += _bonusValue;
        }
        users[rootAddress].pendingBonus.himSelf += _surplus;
        emit BonusAvailableToCollectEvent(userAddress, users[userAddress].id, users[userAddress].referRange, 0);

        // Updating number of assets of the same network
        users[userAddress].referredPlan.accumulatedMembers = users[userAddress].referredPlan.accumulatedMembers - _assetsSameNetwork >=0
        ? users[userAddress].referredPlan.accumulatedMembers - _assetsSameNetwork
        : 0;
        // Updating number of direct assets
        users[userAddress].referredPlan.accumulatedDirectMembers = users[userAddress].referredPlan.accumulatedDirectMembers - _assetsDirect >=0
        ? users[userAddress].referredPlan.accumulatedDirectMembers - _assetsDirect
        : 0;
        //  Updating ReferredRange
        users[userAddress].referRange ++;
    }
}

//TODO: comprobar donde quiera que sea necesario que no es la raiz antes de cualquier operacion de indexacion!!!!