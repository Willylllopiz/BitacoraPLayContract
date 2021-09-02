pragma solidity ^0.6.2;

import "./IMoneyBoxSettings.sol";
import "./CommonBasic.sol";
import "./SafeTRC20.sol";

contract MoneyBox is CommonBasic {
    using SafeTRC20 for ITRC20;

    event UserDeposit(address user, uint32 depositId, uint8 categoryId, uint depositAmount, uint withdrawAmount, uint16 percentage);
    event UserRetireFounds(address user, uint amount);
    event DepositPayed(address admin, address user, uint32 depositId, uint amount);
    event AdminRetireFounds(address admin, uint amount);

    struct User {
        uint id;
        uint totalDeposited;
        uint totalEarned;
        uint balance;
        uint balancePending;
        mapping(uint32 => BoxDeposit) deposits;
        uint32 depositsCount;
        uint depositsPaidCount;
    }

    struct BoxDeposit {
        uint depositId;
        uint startTimestamp;
        uint endTimestamp;

        uint depositAmount;
        uint withdrawAmount;
         
        uint32 categoryId;
        uint16 categoryPercentage;
        uint16 countDays;

        bool payed;
    }

    mapping(address => User) public users;
    uint countUsers;

    uint public usersTotalBalance;
    uint public adminTotalBalance;
    IMoneyBoxSettings _settings;
    address _owner;

    modifier onlyRegisteredUsers() {
        require(isUserActive(msg.sender), "MoneyBox: Only registered users");
        _;
    }

    modifier restrictedWithdrawLostTokens() override {
        require(_settings.isAdmin(msg.sender) || _owner == msg.sender, "MoneyBox: Only admins");
        _;
    }

    modifier restricted() {
        require(_settings.isAdmin(msg.sender), "MoneyBox: Only admins");
        _;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "MoneyBox: Only owner");
        _;
    }

    constructor(ITRC20 depositTokenAddress, IMoneyBoxSettings settings) public {
        depositToken = depositTokenAddress;
        _owner = msg.sender;
        _settings = settings;
    }
    
    //todo: ++++++
    function register() external {
        _register(msg.sender);
    }

    function _register(address user) internal {
        require(users[user].id == 0, "MoneyBox: User already registered");
        users[user].id = ++countUsers;
        //todo: implements...
    }

    function _deposit(address user, uint8 categoryId, uint amount, bool fromBalance) internal {
        (, uint16 catPercentage, uint16 catCountDays, uint catMinDeposit, uint catMaxDeposit) = _settings.getCategoryInfo(categoryId);
        
        User storage userInfo = users[user];
        require(
            amount >= catMinDeposit
            && amount <= catMaxDeposit
            && amount % 10e18 == 0,
            "MoneyBox: Invalid deposit amount"
        );
        if(fromBalance) {
            require(userInfo.balance >= amount, "MoneyBox: Insufficient funds");
            require(depositToken.balanceOf(address(this)) >= amount, "MoneyBox: insufficient funds in the smart contract");
            userInfo.balance -= amount;
        } else depositToken.safeTransferFrom(user, address(this), amount);
        userInfo.depositsCount++;
        userInfo.deposits[userInfo.depositsCount] = BoxDeposit({
            depositId: userInfo.depositsCount,
            startTimestamp: block.timestamp,
            endTimestamp: block.timestamp + (1000 * 60 * 60 * 24 * catCountDays),
            depositAmount: amount,
            withdrawAmount: _getPercentage(amount, catPercentage),
            categoryId: categoryId,
            categoryPercentage: catPercentage,
            countDays: catCountDays,
            payed: false
        });
        userInfo.balancePending += _getPercentage(amount, catPercentage);
        userInfo.totalDeposited += amount;
        
        adminTotalBalance += amount;
        emit UserDeposit(user, userInfo.depositsCount, categoryId, amount, _getPercentage(amount, catPercentage), catPercentage);
    }

    function depositFounds(uint8 categoryId, uint amount) external onlyRegisteredUsers {
        _deposit(msg.sender, categoryId, amount, false);
    }

    function depositFoundsFromBalance(uint8 categoryId, uint amount) external onlyRegisteredUsers {
        _deposit(msg.sender, categoryId, amount, true);
    }

    function retireFounds(uint amount) external onlyRegisteredUsers {
        require(amount > 0, "MoneyBox: Invalid amount");
        require(users[msg.sender].balance >= amount, "MoneyBox: insufficient funds");
        require(depositToken.balanceOf(address(this)) >= amount, "MoneyBox: insufficient funds in the smart contract");
        User storage userInfo = users[msg.sender];
        userInfo.balance -= amount;
        userInfo.totalEarned += amount;
        depositToken.safeTransfer(msg.sender, amount);
        emit UserRetireFounds(msg.sender, amount);
    }

    // endregion

    // Admin
    function retireFoundsAdmin(uint amount) external restricted {
        require(amount > 0, "MoneyBox: Invalid amount");
        require(adminTotalBalance >= amount, "MoneyBox: insufficient funds");
        require(depositToken.balanceOf(address(this)) >= amount, "MoneyBox: insufficient funds in the smart contract");
        adminTotalBalance -= amount;
        depositToken.safeTransfer(msg.sender, amount);
        emit AdminRetireFounds(msg.sender, amount);
    }

    function payUserDeposit(address user, uint32 depositId, bool fromBalance) external restricted {
        require(isUserActive(user), "MoneyBox: Unregistered user");
        User storage userInfo = users[user];
        require(depositId > 0 && depositId <= userInfo.depositsCount, "MoneyBox: depositId not found");
        BoxDeposit storage deposit = userInfo.deposits[depositId];
        require(
            deposit.endTimestamp >= block.timestamp
            && !deposit.payed, "MoneyBox: Deposit validation failed"
        );
        if(fromBalance) {
            require(
                adminTotalBalance >= deposit.withdrawAmount
                && depositToken.balanceOf(address(this)) >= deposit.withdrawAmount,
                "MoneyBox: Insufficient funds"
            );
            adminTotalBalance -= deposit.withdrawAmount;

        } else depositToken.safeTransferFrom(msg.sender, address(this), deposit.withdrawAmount);
        usersTotalBalance += deposit.withdrawAmount;
        deposit.payed = true;
        userInfo.balance += deposit.withdrawAmount;
        userInfo.balancePending -= deposit.withdrawAmount;
        emit DepositPayed(msg.sender, user, depositId, deposit.withdrawAmount);
    }
    //endregion

    function isUserActive(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function _getPercentage(uint amount, uint16 percentage) private pure returns(uint) {
        return amount * percentage / 100;
    }
}
