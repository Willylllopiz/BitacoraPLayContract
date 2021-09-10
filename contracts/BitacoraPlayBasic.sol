pragma solidity ^0.6.2;

import "./IMoneyBox.sol";
import "./BitacoraPlaySettings.sol";

abstract contract BitacoraPlayBasic is BitacoraPlaySettings{      
    event AdminWithdrewFunds(address _admin, uint _amount);  
    event UserWithdrewFunds(address _user, uint _amount);
    event AdminWithdrewUserBonus(address indexed _admin, address indexed _user,uint _amount);
    event UserInvestmentInMoneyBox (address indexed _user, uint8 _categoryId, uint _amount);
    // event AvailableCoursePaymentToProsumer(address indexed _prosumer, address indexed _user, uint _amount);

    
    // modifier restricted() {
    //     require(bitacoraPlaySettings.isAdmin(msg.sender), "BitacoraPlay: Only admins");
    //     _;
    // }

    // struct CareerPlan {
    //     uint accumulatedDirectPlanCareer;
    //     uint accumulatedPlanCareer;
    //     bool activeCareerPlan;
    // }

    // struct ProsumerPlan {
    //     bool activate;
    //     bool approved;
    //     uint accumulatedDirectPlanProsumer; //Cantidad  acumulada de prosumers directos que han pagado el plan prosumer
    //     mapping(uint8 => uint) accumulatedViewsPerCycle;
    // }

    uint public lastUserId = 2;
    uint public globalBalance = 0;
    uint public administrativeBalance = 0;

// External Settings
    // Referral Plan Payments
    uint public referralPlanPrice = 35e18;
    uint public referralDirectPayment = 18e18; //60% of referralPlanPrice.
    // Career Plan Payments
    // uint public careerPlanPrice = 50e18;
    uint8 public constant ACTIVE_LEVEL = 5;


 

    address public owner;
    address externalAddress;
    address rootAddress;

    IMoneyBox moneyBox;
    BitacoraPlaySettings bitacoraPlaySettings;


    // function withdrawAdminFounds(uint _amount) external restricted {
    //     require(0 < _amount, "BitacoraPlay: Invalid amount");
    //     require(_amount <= administrativeBalance, "BitacoraPlay: insufficient funds");
    //     depositToken.safeTransfer(msg.sender, _amount);
    //     administrativeBalance -= _amount;
    //     globalBalance -= _amount;
    //     emit AdminWithdrewFunds(msg.sender, _amount);
    // }

    // function withdrawUserBonusByAdmin(uint _amount, address _user) external restricted {
    //     require(0 < _amount, "BitacoraPlay: Invalid amount");
    //     require(isUserExists(_user), "user is not exists");
    //     require(_amount <= users[_user].pendingBonus.adminBonus, "BitacoraPlay: insufficient funds");
    //     depositToken.safeTransfer(msg.sender, _amount);
    //     administrativeBalance -= _amount;
    //     globalBalance -= _amount;
    //     emit AdminWithdrewUserBonus(msg.sender, _user, _amount);
    // }

    // function witdrawUserFounds(uint _amount) external {
    //     require(isUserExists(msg.sender), "user is not exists");
    //     require(0 < _amount, "BitacoraPlay: Invalid amount");
    //     require(_amount <= users[msg.sender].pendingBonus.himSelf, "BitacoraPlay: insufficient funds");
    //     depositToken.safeTransfer(msg.sender, _amount);
    //     users[msg.sender].pendingBonus.himSelf -= _amount;
    //     globalBalance -= _amount;
    //     emit UserWithdrewFunds(msg.sender, _amount);
    // }

    // function userInvestmentInMoneyBox(uint _amount, uint8 _categoryId) external {
    //     require(isUserExists(msg.sender), "user is not exists");
    //     require(50e18 < _amount, "BitacoraPlay: Invalid amount");
    //     require(_amount <= users[msg.sender].pendingBonus.moneyBox, "BitacoraPlay: insufficient funds");
    //     depositToken.safeIncreaseAllowance(address(moneyBox), _amount);
    //     moneyBox.addToBalance( msg.sender, _amount);        
    //     users[msg.sender].pendingBonus.moneyBox -= _amount;
    //     globalBalance -= _amount;
    //     emit UserInvestmentInMoneyBox(msg.sender, _categoryId, _amount);
    // }
}