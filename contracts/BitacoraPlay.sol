pragma solidity ^0.6.2;
// SPDX-License-Identifier: MIT

import "./IMoneyBox.sol";
import "./BitacoraPlayBasic.sol";
// import "./CommonBasic.sol";

contract BitacoraPlay is BitacoraPlayBasic {


    modifier restricted() {
        require(msg.sender == owner, "restricted");
        _;
    }

    function withdrawBalanceOfReferredPlan () external {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require( isActivatedMembership(msg.sender), "user is not active, Pay membership.");
        require(users[msg.sender].referredPlan.accumulatedDirectReferralPayments > 100e18, "you do not have enough balance to withdraw.");
        address(uint160(msg.sender)).transfer(users[msg.sender].referredPlan.accumulatedDirectReferralPayments);
    }

    // function withDrawBonus () public{
    //     require(isUserExists(msg.sender), "user is not exists. Register first.");
    // }

    constructor(address _externalAddress, address _rootAddress, IMoneyBox _moneyBox) public {
        owner = msg.sender;
        initializeValues();
        // _initializeCommonBasic(msg.sender, _depositTokenAddress);

        moneyBox = _moneyBox;

        externalAddress = _externalAddress;
        rootAddress = _rootAddress;
        users[rootAddress].id = 1;
        users[rootAddress].referrer = address(0);
        idToAddress[1] = rootAddress;
        users[_rootAddress].referRange = ReferredRange.Guru;
        users[_rootAddress].careerPlan.activeCareerPlan = true;
    }

    function initializeValues() internal {
        // Rookie Bonus Configuration
        rangeConfig[ uint(ReferredRange.Rookie) ] = RangeConfig({
        assetsDirect: 0,
        assetsSameNetwork: 0,
        qualifyingCycles: 0,
        bonusValue: 0e18,
        surplus: 0e18,
        remainderVehicleBonus: 0e18
        });
        // // Junior Bonus Configuration
        rangeConfig [ uint(ReferredRange.Junior) ] = RangeConfig({
        assetsDirect: 30,
        assetsSameNetwork: 3000,
        qualifyingCycles: 1,
        bonusValue: 500e18,
        surplus: 40e18, // TODO: en el documento dice que sobran 50 y son 40 revisar esto
        remainderVehicleBonus: 540e18
        });
        // Leader Bonus Configuration
        rangeConfig[ uint(ReferredRange.Leader) ] = RangeConfig({
        assetsDirect: 100,
        assetsSameNetwork: 7000,
        qualifyingCycles: 2,
        bonusValue: 1800e18,
        surplus: 0e18,
        remainderVehicleBonus: 3240e18
        });
        // Guru Bonus Configuration
        rangeConfig[ uint(ReferredRange.Guru) ] = RangeConfig({
        assetsDirect: 300,
        assetsSameNetwork: 20000,
        qualifyingCycles: 2,
        bonusValue: 4500e18,
        surplus: 0e18,
        remainderVehicleBonus: 9900e18
        });
        // GuruVehicle Bonus Configuration
        rangeConfig[ uint(ReferredRange.GuruVehicle) ] = RangeConfig({
        assetsDirect: 300,
        assetsSameNetwork: 20000,
        qualifyingCycles: 2,
        bonusValue: 0e18,
        surplus: 0e18,
        remainderVehicleBonus: 14400e18
        });

        careerRangeConfig [uint(CareerRange.AcademicPromoter)] = 30;
        careerRangeConfig [uint(CareerRange.AcademicLeader)] = 70;
        careerRangeConfig [uint(CareerRange.AcademicCommunity)] = 1000;
        careerRangeConfig [uint(CareerRange.Perseverance)] = 5000;


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

    function activateCareerPlan() external payable{
        require(msg.value == referralPlanPrice, "invalid price");//TODO: cambiar esta comprobacion para usdt
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require( isActivatedMembership(msg.sender), "user already active this month.");
        payCareerPlanActivation(msg.sender);
    }

    function payCareerPlanActivation(address _user) internal {
        users[_user].careerPlan.activeCareerPlan = true;
        users[users[_user].referrer].careerPlan.accumulatedDirectPlanCareer ++;

    }

    function updateActivePlanCareer(uint8 _level, address _referrerAddress) private {
        if(_level > 0 && _referrerAddress != rootAddress) {
            users[_referrerAddress].careerPlan.accumulatedPlanCareer ++;
            if (checkCareerRange(_referrerAddress, users[_referrerAddress].careerRange)){
                emit CompletedCareerBonusEvent(_referrerAddress, users[_referrerAddress].id, users[_referrerAddress].careerRange);
                changeCareerRange(_referrerAddress);
            }
            updateActivePlanCareer(_level - 1, users[_referrerAddress].referrer);
        }
        return;
    }

    function payMonth(address _user) internal {
        require(isUserExists(_user), "user is not exists. Register first.");
        users[_user].activationDate =  block.timestamp + 30 days;
        users[users[_user].referrer].referredPlan.accumulatedDirectMembers ++;
        users[users[_user].referrer].referredPlan.accumulatedDirectReferralPayments += referralDirectPayment;
        updateActiveMembers(ACTIVE_LEVEL, users[_user].referrer);
        globalBalance += referralPlanPrice;
    }

    function payMonthly() external payable {
        require(msg.value == referralPlanPrice, "invalid price");//TODO: cambiar esta comprobacion para usdt
        require( isActivatedMembership(msg.sender), "user already active this month.");
        payMonth(msg.sender);
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
        users[userAddress].referRange = ReferredRange.Rookie;

        users[userAddress].careerPlan.activeCareerPlan = false;

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

    function signUp(address referrerAddress) external payable {
        require(msg.value == referralPlanPrice, "invalid registration cost");
        registration(msg.sender, referrerAddress);
    }

    function updateActiveMembers(uint8 _level, address _referrerAddress) private {
        if(_level > 0 && _referrerAddress != rootAddress){
            users[_referrerAddress].referredPlan.accumulatedMembers ++;
            users[_referrerAddress].referredPlan.accumulatedPayments += 0.36e18;
            if (checkRange(_referrerAddress, users[_referrerAddress].referRange)){
                emit CompletedReferredBonusEvent(_referrerAddress, users[_referrerAddress].id, users[_referrerAddress].referRange);
                changeRange(_referrerAddress);
            }
            updateActiveMembers(_level - 1, users[_referrerAddress].referrer);
        }
        return;
    }

    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function isActivatedMembership(address user) public view returns(bool) {
        return block.timestamp <=  users[user].activationDate;
    }

    // Check that a user (_userAddress) is in a specified range (_range) in Referred Plan
    function checkCareerRange(address _userAddress, CareerRange _range) public view returns(bool) {
        return _range == CareerRange.AcademicPromoter ? users[ _userAddress ].careerPlan.accumulatedDirectPlanCareer >= careerRangeConfig[uint(_range)] :
        _range == CareerRange.AcademicLeader ? users[ _userAddress ].careerPlan.accumulatedDirectPlanCareer >= careerRangeConfig[uint(_range)] :
        _range == CareerRange.AcademicCommunity ? users[ _userAddress ].careerPlan.accumulatedPlanCareer >= careerRangeConfig[uint(_range)] :
        _range == CareerRange.Perseverance ? users[ _userAddress ].careerPlan.accumulatedPlanCareer >= careerRangeConfig[uint(_range)] :
        false;
    }

    // Check that a user (_userAddress) is in a specified range (_range) in Referred Plan
    function checkRange(address _userAddress, ReferredRange _range) public view returns(bool) {
        return users[ _userAddress ].referredPlan.accumulatedMembers >= (rangeConfig[ uint(_range)].assetsSameNetwork *
        rangeConfig[ uint(_range) ].qualifyingCycles ) &&
        users[ _userAddress ].referredPlan.accumulatedDirectMembers >= rangeConfig[ uint(_range) ].assetsDirect;
    }

    function changeRange(address userAddress) private {
        users[userAddress].referredPlan.accumulatedPayments -= rangeConfig[uint(users[userAddress].referRange)].bonusValue;
        if (users[userAddress].referRange == ReferredRange.Junior){
            users[userAddress].pendingBonus.moneyBox += rangeConfig[uint(users[userAddress].referRange)].bonusValue;
            emit AvailableBalanceForMoneyBox(userAddress, rangeConfig[uint(users[userAddress].referRange)].bonusValue);
        }
        else{
            users[userAddress].pendingBonus.adminBonus += rangeConfig[uint(users[userAddress].referRange)].bonusValue;
        }
        users[rootAddress].pendingBonus.himSelf += rangeConfig[uint(users[userAddress].referRange)].surplus;
        emit BonusAvailableToCollectEvent(userAddress, users[userAddress].id, users[userAddress].referRange);

        // Updating number of assets of the same network
        users[userAddress].referredPlan.accumulatedMembers = users[userAddress].referredPlan.accumulatedMembers - rangeConfig[uint(users[userAddress].referRange)].assetsSameNetwork >=0
        ? users[userAddress].referredPlan.accumulatedMembers - rangeConfig[uint(users[userAddress].referRange)].assetsSameNetwork
        : 0;
        // Updating number of direct assets
        users[userAddress].referredPlan.accumulatedDirectMembers = users[userAddress].referredPlan.accumulatedDirectMembers - rangeConfig[uint(users[userAddress].referRange)].assetsDirect >=0
        ? users[userAddress].referredPlan.accumulatedDirectMembers - rangeConfig[uint(users[userAddress].referRange)].assetsDirect
        : 0;
        //  Updating ReferredRange
        users[userAddress].referRange =  users[userAddress].referRange == ReferredRange.Junior ? ReferredRange.Leader :
        users[userAddress].referRange == ReferredRange.Leader ? ReferredRange.Guru : ReferredRange.GuruVehicle;
    }

    function changeCareerRange(address _userAddress) private {
        users[ _userAddress ].careerPlan.accumulatedPlanCareer -= careerRangeConfig(uint(users[_userAddress].careerRange));
    }
}
