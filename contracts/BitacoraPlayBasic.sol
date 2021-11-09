pragma solidity ^0.6.2;

import "./IMoneyBox.sol";
import "./ISettingsBasic.sol";
import "./CommonBasic.sol";
import "./SafeTRC20.sol";

abstract contract BitacoraPlayBasic is CommonBasic {      
    using SafeTRC20 for ITRC20;

    event AdminWithdrewFunds(address _admin, uint _amount);  
    event UserWithdrewFunds(address _user, uint _amount);
    event AdminWithdrewUserBonus(address indexed _admin, address indexed _user,uint _amount);
    event UserInvestmentInMoneyBox (address indexed _user, uint8 _categoryId, uint _amount);
   
    uint public administrativeBalance; 
    uint public globalBalance;

    IMoneyBox moneyBox;
    ISettingsBasic settingsBasic;

    modifier restricted() {
        require(!_locked || msg.sender == _owner);
        require(settingsBasic.isAdmin(msg.sender));
        _;
    }

    modifier safeTransferAmount(uint _amount){
        require(_amount <= globalBalance);
        _;
    }

    function isUserExists(address _user) public view virtual returns (bool);

    function withdrawAdminFounds(uint _amount) external restricted safeTransferAmount(_amount){
        require(0 < _amount);
        require(_amount <= administrativeBalance);
        depositToken.safeTransfer(msg.sender, _amount);
        administrativeBalance -= _amount;
        globalBalance -= _amount;
        emit AdminWithdrewFunds(msg.sender, _amount);
    }

    function withdrawUserBonusByAdmin(uint _amount, address _user) external virtual;

    function witdrawUserFounds(uint _amount) external virtual; 

    function userInvestmentInMoneyBox(uint _amount, uint8 _categoryId) external virtual;
}