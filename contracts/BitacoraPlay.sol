pragma solidity ^0.6.2;
// SPDX-License-Identifier: MIT

import "./IMoneyBox.sol";
import "./BitacoraPlayBasic.sol";//ya
import "./CommonBasic.sol";

contract BitacoraPlay is BitacoraPlayBasic, CommonBasic {

    constructor(ITRC20 _depositTokenAddress, address _externalAddress, address _rootAddress, IMoneyBox _moneyBox, IBitacoraPlaySettings _bitacoraPlaySettings) public {
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
        users[_rootAddress].careerPlan.activeCareerPlan = true;
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

    modifier restricted() {
        require(bitacoraPlaySettings.isAdmin(msg.sender), "BitacoraPlay: Only admins");
        _;
    }

    // Start Region Referred Plan

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

    function signUp(address referrerAddress) external {
        // require(msg.value == referralPlanPrice, "invalid registration cost");
        registration(msg.sender, referrerAddress);
    }

    function payMonth(address _user) private {
        require(isUserExists(_user), "user is not exists. Register first.");
        depositToken.safeTransferFrom(_user, address(this), referralPlanPrice);
        users[_user].activationDate =  block.timestamp + 30 days;
        users[users[_user].referrer].referredPlan.accumulatedDirectMembers ++;
        users[users[_user].referrer].referredPlan.accumulatedDirectReferralPayments += referralDirectPayment;
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

    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
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

    // End Region Referred Plan

    // Start Region Career Plan

    function activateCareerPlan() external{      
        require( isActivatedMembership(msg.sender), "user already active this month.");
        payCareerPlanActivation(msg.sender);
    }

    function payCareerPlanActivation(address _user) private {
        require(isUserExists(_user), "user is not exists. Register first.");
        depositToken.safeTransferFrom(_user, address(this), careerPlanPrice);
        users[_user].careerPlan.activeCareerPlan = true;
        users[users[_user].referrer].careerPlan.accumulatedDirectPlanCareer ++;
        updateActivePlanCareer(ACTIVE_LEVEL,users[_user].referrer);
        administrativeBalance +=10e18;
        emit AvailableAdministrativeBalance(10e18);
        globalBalance += careerPlanPrice;
    }

    function updateActivePlanCareer(uint8 _level, address _referrerAddress) private {
        if(_level > 0 && _referrerAddress != rootAddress) {
            users[_referrerAddress].careerPlan.accumulatedPlanCareer ++;
            if (checkCareerRange(_referrerAddress, users[_referrerAddress].careerRange)){
                 if ( 3 > users[_referrerAddress].careerRange){
                     changeCareerRange(_referrerAddress);
                 }
                else{
                     users[rootAddress].pendingBonus.himSelf += 3e18;
                 }

                emit CompletedBonusEvent(_referrerAddress, users[_referrerAddress].id, users[_referrerAddress].careerRange, 1);                
            }
            updateActivePlanCareer(_level - 1, users[_referrerAddress].referrer);
        }
        return;
    }

     // Check that a user (_userAddress) is in a specified range (_range) in Referred Plan
    function checkCareerRange(address _userAddress, uint8 _range) public view returns(bool) {
        (uint _assetsDirect, uint _assetsSameNetwork, , ) = bitacoraPlaySettings.getCareerConfigInfo(_range);
        return _range <= 1 ? users[ _userAddress ].careerPlan.accumulatedDirectPlanCareer >= _assetsDirect :
        users[ _userAddress ].careerPlan.accumulatedPlanCareer >= _assetsSameNetwork;
    }

    function changeCareerRange(address _userAddress) private {
        (uint _assetsDirect, uint _assetsSameNetwork, uint _bonusValue,) = bitacoraPlaySettings.getCareerConfigInfo(users[_userAddress].careerRange);
        if (users[ _userAddress ].careerRange <= 1 ){
            users[ _userAddress ].careerPlan.accumulatedDirectPlanCareer -= _assetsDirect;
            users[_userAddress].pendingBonus.adminBonus += _bonusValue;
            emit BonusAvailableToCollectEvent(_userAddress, users[_userAddress].id, users[_userAddress].careerRange, 1);
        }
        if (users[ _userAddress ].careerRange == 2 || users[ _userAddress ].careerRange == 3){
            users[ _userAddress ].careerPlan.accumulatedPlanCareer -= _assetsSameNetwork;
            users[_userAddress].pendingBonus.moneyBox += _bonusValue;
            emit AvailableBalanceForMoneyBox(_userAddress, _bonusValue);
        }
        emit CompletedBonusEvent(_userAddress, users[_userAddress].id,users[_userAddress].careerRange, 1);
        //  Updating CareerRange
        users[ _userAddress ].careerRange ++;
    }

    // End Region Career Plan

    //Start Region Prosumer Plan
    

    //End Region Prosumer Plan

    function withdrawAdminFounds(uint _amount) external restricted {
        require(0 < _amount, "BitacoraPlay: Invalid amount");
        require(_amount <= administrativeBalance, "BitacoraPlay: insufficient funds");
        depositToken.safeTransfer(msg.sender, _amount);
        administrativeBalance -= _amount;
        globalBalance -= _amount;
        emit AdminWithdrewFunds(msg.sender, _amount);
    }

    function withdrawUserBonusByAdmin(uint _amount, address _user) external restricted {
        require(0 < _amount, "BitacoraPlay: Invalid amount");
        require(isUserExists(_user), "user is not exists");
        require(_amount <= users[_user].pendingBonus.adminBonus, "BitacoraPlay: insufficient funds");
        depositToken.safeTransfer(msg.sender, _amount);
        administrativeBalance -= _amount;
        globalBalance -= _amount;
        emit AdminWithdrewUserBonus(msg.sender, _user, _amount);
    }

    function witdrawUserFounds(uint _amount) external {
        require(isUserExists(msg.sender), "user is not exists");
        require(0 < _amount, "BitacoraPlay: Invalid amount");
        require(_amount <= users[msg.sender].pendingBonus.himSelf, "BitacoraPlay: insufficient funds");
        depositToken.safeTransfer(msg.sender, _amount);
        users[msg.sender].pendingBonus.himSelf -= _amount;
        globalBalance -= _amount;
        emit UserWithdrewFunds(msg.sender, _amount);
    }

    function userInvestmentInMoneyBox(uint _amount, uint8 _categoryId) external {
        require(isUserExists(msg.sender), "user is not exists");
        require(50e18 < _amount, "BitacoraPlay: Invalid amount");
        require(_amount <= users[msg.sender].pendingBonus.moneyBox, "BitacoraPlay: insufficient funds");
        depositToken.safeIncreaseAllowance(address(moneyBox), _amount);
        moneyBox.depositFounds(_categoryId, msg.sender, _amount);        
        users[msg.sender].pendingBonus.moneyBox -= _amount;
        globalBalance -= _amount;
        emit UserInvestmentInMoneyBox(msg.sender, _categoryId, _amount);
    }
}