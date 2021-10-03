pragma solidity ^0.6.2;

import "./CommonBasic.sol";
import "./SafeTRC20.sol";
import "./IMoneyBoxSettings.sol";

interface IBitacoraBasic {
    function isUserExists(address user) external view returns (bool);
    function getUserInfo(address user) external view returns (uint, address);
}

contract MoneyBox is CommonBasic {
    using SafeTRC20 for ITRC20;

    event SignUp(address user);
    event UserEarnBonus(address sponsor, address user, uint8 bonusId, uint amount);
    event UserAccumulatePayment(address sponsor, address user);
    event UserDeposit(address user, uint32 depositId, uint8 categoryId, uint depositAmount, uint withdrawAmount, uint16 percentage);
    event UserRetireFounds(address user, uint amount);
    event DepositPayed(address admin, address user, uint32 depositId, uint amount);
    event AdminRetireFounds(address admin, uint amount);
    event AdminRetireFoundsFromUsersBalance(address admin, uint amount);
    event AdminReturnFoundsToUsersBalance(address admin, uint amount);
    event AdminRetireFoundsFromBonusBalance(address admin, uint amount);
    event AdminReturnFoundsToBonusBalance(address admin, uint amount);
    event AdminRetireAllFounds(address admin, uint amount);

    enum DepositType {
        Balance,
        User,
        Bitacora
    }

    struct User {
        uint id;
        uint balance;
        mapping(uint32 => BoxDeposit) deposits;
        uint32 depositsCount;
        Bonus bonus;
    }

    struct Bonus {
        uint8 lastBonus;
        uint accumulatedPayments;
        uint accumulatedAmount;
    }

    struct BoxDeposit {
        bool active;
        uint endTimestamp;
        uint withdrawAmount;
    }

    mapping(address => User) users;
    uint countUsers;

    uint public bonusTotalBalance;
    uint public bonusAdminExtracted;
    uint public usersTotalBalance;
    uint public usersBalanceAdminExtracted;
    
    uint public adminTotalBalance;
    uint public totalBalance;

    IMoneyBoxSettings _settings;
    IBitacoraBasic _bitacoraImpl;

    modifier onlyRegisteredUsers() {
        require(isUserActive(msg.sender), "[MoneyBox]: Only registered users");
        _;
    }

    modifier restrictedWithdrawLostTokens() override {
        require(_settings.isAdmin(msg.sender) || _owner == msg.sender, "[MoneyBox]: Only admins");
        _;
    }

    modifier restricted() {
        require(!_locked || msg.sender == _owner, "MoneyBox: locked");
        require(_settings.isAdmin(msg.sender), "[MoneyBox]: Only admins");
        _;
    }

    constructor() public {
        _owner = msg.sender;
        _locked = true;
    }

    function initialize(ITRC20 depositTokenAddress, IMoneyBoxSettings settings, IBitacoraBasic bitacoraImpl) external onlyOwner {
        depositToken = depositTokenAddress;
        _settings = settings;
        _bitacoraImpl = bitacoraImpl;
        _locked = false;
    }
    
    //todo: ++++++
    function registration() external onlyUnlocked {
        _registration(msg.sender, msg.sender);
    }

    function _registration(address user, address provider) private returns(uint) {
        require(address(_bitacoraImpl) != address(0), "[MoneyBox]: Not bitacora implementation");
        require(users[user].id == 0, "[MoneyBox]: User already registered");
        (uint userId, address sponsor) = _bitacoraImpl.getUserInfo(user);
        require(userId > 0, "[MoneyBox]: User isn't valid");
        (uint registerPrice, uint amountForBonus, uint8 bonusesCount) = _settings.getLogicSettings();
        depositToken.safeTransferFrom(provider, address(this), registerPrice);
        ++countUsers;
        users[user].id = userId;
        adminTotalBalance += (registerPrice - amountForBonus);
        totalBalance += registerPrice;
        applyDistribution(user, sponsor, amountForBonus, bonusesCount);
        emit SignUp(user);
        return registerPrice;
    }

    function applyDistribution(address user, address sponsor, uint amountForBonus, uint8 bonusesCount) private returns(bool) {
        User storage sponsorInfo = users[sponsor];
        if(sponsorInfo.id == 0) {
            adminTotalBalance += amountForBonus;
            return false;
        }
        bonusTotalBalance += amountForBonus;
        Bonus storage bonus = sponsorInfo.bonus;
        bonus.accumulatedPayments++;
        bonus.accumulatedAmount += amountForBonus;
        emit UserAccumulatePayment(sponsor, user);
        if(bonus.lastBonus < bonusesCount) {
            (uint64 accumulateNecessary, uint amountNecessary) = _settings.getBonusDistribution(bonus.lastBonus + 1);
            if(bonus.accumulatedPayments >= accumulateNecessary && bonus.accumulatedAmount >= amountNecessary) {
                sponsorInfo.balance += amountNecessary;
                if(bonusTotalBalance >= bonus.accumulatedAmount) {
                    bonusTotalBalance -= bonus.accumulatedAmount;
                    adminTotalBalance += (bonus.accumulatedAmount - amountNecessary);
                    usersTotalBalance += amountNecessary;
                } else {
                    usersTotalBalance += (bonusTotalBalance >= amountNecessary) ? amountNecessary : bonusTotalBalance;
                    usersBalanceAdminExtracted += (bonusTotalBalance >= amountNecessary)
                     ? 0 : (amountNecessary - bonusTotalBalance);
                    bonusAdminExtracted -= (bonusAdminExtracted >= (bonus.accumulatedAmount - bonusTotalBalance))
                     ? (bonus.accumulatedAmount - bonusTotalBalance) : bonusAdminExtracted;
                    bonusTotalBalance = 0;
                }
                bonus.lastBonus++;
                bonus.accumulatedAmount = 0;
                emit UserEarnBonus(sponsor, user, bonus.lastBonus, amountNecessary);
            }
        }
        return true;
    }

    function _deposit(address user, uint8 categoryId, uint amount, DepositType depositType) internal {
        (, uint16 catPercentage, uint16 catCountDays, uint catMinDeposit, uint catMaxDeposit, bool active) = _settings.getCategoryInfo(categoryId);
        require(active, "[MoneyBox]: The category is inactive");
        require(
            amount >= catMinDeposit
            && amount <= catMaxDeposit
            && amount % 10e6 == 0,
            "[MoneyBox]: Invalid deposit amount"
        );
        User storage userInfo = users[user];
        
        if(depositType == DepositType.Balance) {
            require(userInfo.balance >= amount, "[MoneyBox]: Insufficient funds");
            require(usersTotalBalance >= amount, "[MoneyBox]: insufficient funds in the smart contract");
            userInfo.balance -= amount;
            usersTotalBalance -= amount;
        } else {
            depositToken.safeTransferFrom(
                depositType == DepositType.Bitacora ? address(_bitacoraImpl) : user,
                address(this), amount);
            totalBalance += amount;
        }
        userInfo.depositsCount++;
        userInfo.deposits[userInfo.depositsCount] = BoxDeposit({
            // endTimestamp: block.timestamp + ((1 days) * catCountDays),  //todo: USE THIS
            endTimestamp: block.timestamp + ((1 minutes) * catCountDays), // + (1000 * 60 * 60 * 24 * catCountDays),
            withdrawAmount: _getPercentage(amount, catPercentage),
            active: true
        });        
        adminTotalBalance += amount;
        emit UserDeposit(user, userInfo.depositsCount, categoryId, amount, _getPercentage(amount, catPercentage), catPercentage);
    }

    function depositFounds(uint8 categoryId, uint amount) external onlyRegisteredUsers onlyUnlocked {
        _deposit(msg.sender, categoryId, amount, DepositType.User);
    }

    function depositFoundsFromBitacora(address user, uint8 categoryId, uint amount) external override onlyUnlocked {
        require(msg.sender == address(_bitacoraImpl), "Only Bitacora");
        _deposit(
            user,
            categoryId,
            !isUserActive(user) ? amount - _registration(user, address(_bitacoraImpl)) : amount,
            DepositType.Bitacora
        );
    }

    function depositFoundsFromBalance(uint8 categoryId, uint amount) external onlyRegisteredUsers onlyUnlocked {
        _deposit(msg.sender, categoryId, amount, DepositType.Balance);
    }

    function retireFounds(uint amount) external onlyRegisteredUsers onlyUnlocked {
        require(amount > 0, "[MoneyBox]: Invalid amount");
        require(users[msg.sender].balance >= amount, "[MoneyBox]: insufficient funds");
        require(usersTotalBalance >= amount, "[MoneyBox]: insufficient funds in the smart contract");
        depositToken.safeTransfer(msg.sender, amount);
        User storage userInfo = users[msg.sender];
        userInfo.balance -= amount;
        usersTotalBalance -= amount;
        totalBalance -= amount;
        emit UserRetireFounds(msg.sender, amount);
    }

    // endregion

    // Admin
    function changeSettingsImpl(IMoneyBoxSettings impl) external onlyOwner onlyUnlocked {
        _settings = impl;
    }

    function changeBitacoraImpl(IBitacoraBasic impl) external onlyOwner onlyUnlocked {
        _bitacoraImpl = impl;
    }

    function adminRetireFounds(uint amount) external restricted {
        require(amount > 0, "[MoneyBox]: Invalid amount");
        require(adminTotalBalance >= amount, "[MoneyBox]: insufficient funds");
        depositToken.safeTransfer(msg.sender, amount);
        adminTotalBalance -= amount;
        totalBalance -= amount;
        emit AdminRetireFounds(msg.sender, amount);
    }

    function adminRetireFoundsFromUsersBalance(uint amount) external restricted {
        require(amount > 0, "[MoneyBox]: Invalid amount");
        require(usersTotalBalance >= amount, "[MoneyBox]: insufficient funds");
        depositToken.safeTransfer(msg.sender, amount);
        usersTotalBalance -= amount;
        usersBalanceAdminExtracted += amount;
        totalBalance -= amount;
        emit AdminRetireFoundsFromUsersBalance(msg.sender, amount);
    }

    function adminReturnFoundsToUsersBalance(uint amount) external restricted {
        require(amount > 0, "[MoneyBox]: Invalid amount");
        require(usersBalanceAdminExtracted >= amount, "[MoneyBox]: Exceeds retired founds");
        depositToken.safeTransferFrom(msg.sender, address(this), amount);
        usersTotalBalance += amount;
        usersBalanceAdminExtracted -= amount;
        totalBalance += amount;
        emit AdminReturnFoundsToUsersBalance(msg.sender, amount);
    }

    function adminRetireFoundsFromBonusBalance(uint amount) external restricted {
        require(amount > 0, "[MoneyBox]: Invalid amount");
        require(bonusTotalBalance >= amount, "[MoneyBox]: insufficient funds");
        depositToken.safeTransfer(msg.sender, amount);
        bonusTotalBalance -= amount;
        bonusAdminExtracted += amount;
        totalBalance -= amount;
        emit AdminRetireFoundsFromBonusBalance(msg.sender, amount);
    }

    function adminReturnFoundsToBonusBalance(uint amount) external restricted {
        require(amount > 0, "[MoneyBox]: Invalid amount");
        require(bonusAdminExtracted >= amount, "[MoneyBox]: Exceeds retired founds");
        depositToken.safeTransferFrom(msg.sender, address(this), amount);
        bonusTotalBalance += amount;
        bonusAdminExtracted -= amount;
        totalBalance += amount;
        emit AdminReturnFoundsToBonusBalance(msg.sender, amount);
    }

    function adminRetireAllFounds() external restricted {
        require(totalBalance > 0, "[MoneyBox]: Invalid amount");
        depositToken.safeTransfer(msg.sender, totalBalance);
        emit AdminRetireAllFounds(msg.sender, totalBalance);
        bonusAdminExtracted += bonusTotalBalance;
        usersBalanceAdminExtracted += usersTotalBalance;
        usersTotalBalance = 0;
        bonusTotalBalance = 0;
        adminTotalBalance = 0;
        totalBalance = 0;
    }

    function payUserDeposit(address user, uint32 depositId, bool fromBalance) external restricted onlyUnlocked() {
        require(isUserActive(user), "[MoneyBox]: Unregistered user");
        User storage userInfo = users[user];
        require(userInfo.deposits[depositId].active, "[MoneyBox]: depositId not found");
        BoxDeposit storage deposit = userInfo.deposits[depositId];
        require(deposit.endTimestamp >= block.timestamp, "[MoneyBox]: Deposit validation failed");
        if(fromBalance) {
            require(adminTotalBalance >= deposit.withdrawAmount, "[MoneyBox]: Insufficient funds");
            adminTotalBalance -= deposit.withdrawAmount;
        }
        else {
            depositToken.safeTransferFrom(msg.sender, address(this), deposit.withdrawAmount);
            totalBalance += deposit.withdrawAmount;
        }
        usersTotalBalance += deposit.withdrawAmount;
        userInfo.balance += deposit.withdrawAmount;
        emit DepositPayed(msg.sender, user, depositId, deposit.withdrawAmount);
        // deposit.active = false;
        delete userInfo.deposits[depositId];
    }

    
    //endregion

    function isUserActive(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    /**
     * @dev Returns the users informations: (uint id, uint balance, uint32 depositsCount).
     * @param user The address of user.
     * @return (uint id, uint balance, uint32 depositsCount)
     */
    function getUserInfo(address user) public view returns (uint, uint, uint32) {
        User storage userInfo = users[user];
        return (userInfo.id, userInfo.balance, userInfo.depositsCount);
    }

    /**
     * @dev Returns the user's deposit informations:
     * ( 
     *   uint depositId, uint startTimestamp, uint endTimestamp, uint depositAmount,
     *   uint withdrawAmount, uint32 categoryId, uint16 categoryPercentage, uint16 countDays, bool payed
     * )
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param user The address of user.
     * @return (uint id, uint totalDeposited, uint totalEarned, uint balance, uint balancePending, uint32 depositsCount, uint32 depositsPaidCount)
     */
    function getDepositInfo(address user, uint32 depositId) public view returns (bool, uint, uint) {
        BoxDeposit storage info = users[user].deposits[depositId];
        return (info.active, info.endTimestamp, info.withdrawAmount);
    }

    function _getPercentage(uint amount, uint16 percentage) private pure returns(uint) {
        return amount * percentage / 100;
    }
}
