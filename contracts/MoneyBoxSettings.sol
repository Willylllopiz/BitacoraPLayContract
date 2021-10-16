pragma solidity ^0.6.2;

import "./SettingsBasic.sol";

contract MoneyBoxSettings is SettingsBasic {
    event CategoryConfigAdded(address indexed admin, uint8 categoryId, bytes4 name, uint16 percentage, uint16 countDays, uint minDeposit, uint maxDeposit);
    event CategoryConfigUpdatedStatus(address indexed admin, uint8 categoryId, bool active);
    event CategoryConfigUpdated(address indexed admin, uint8 categoryId, bytes4 name, uint16 percentage, uint16 countDays, uint minDeposit, uint maxDeposit);
    event BonusDistributionAdded(address indexed admin, uint8 bonusDistributionId, uint64 accumulateNecessary, uint amount);
    event BonusDistributionUpdated(address indexed admin, uint8 bonusDistributionId, uint64 accumulateNecessary, uint amount);
    event RegisterSettingsUpdated(address indexed admin, uint registerPrice, uint amountForBonus);
    
    struct CategoryConfig {
        bytes4 name;
        uint16 percentage;
        uint16 countDays;
        uint minDeposit;
        uint maxDeposit;
        bool active;
    }
    mapping(uint8 => CategoryConfig) public _categoryConfig;
    uint8 _categoriesCount;

    uint registerPrice;
    uint amountForBonus;
    mapping(uint8 => BonusDistribution) public bonusDistribution;
    uint8 bonusesCount;

    struct BonusDistribution {
        uint64 accumulateNecessary;
        uint amount;
    }

    constructor() public {
        _owner = msg.sender;
        _locked = true;
    }

    function initialize(ITRC20 _depositTokenAddress) external onlyOwner {
        _initializeSettingsBasic(_depositTokenAddress);
        _categoriesCount = 3;
        _categoryConfig[1] = CategoryConfig({
            name: "M3",
            percentage: 112,
            countDays: 90,
            minDeposit: 10e6,
            maxDeposit: 10000e6,
            active: true
        });
        _categoryConfig[2] = CategoryConfig({
            name: "M6",
            percentage: 142,
            countDays: 180,
            minDeposit: 10e6,
            maxDeposit: 10000e6,
            active: true
        });
        _categoryConfig[3] = CategoryConfig({
            name: "M12",
            percentage: 244,
            countDays: 360,
            minDeposit: 10e6,
            maxDeposit: 10000e6,
            active: true
        });
        
        registerPrice = 50e6;
        amountForBonus = 40e6;
        bonusDistribution[1] = BonusDistribution({
            accumulateNecessary: 30,
            amount: 1000e6
        });
        bonusDistribution[2] = BonusDistribution({
            accumulateNecessary: 100,
            amount: 1750e6
        });
        bonusDistribution[3] = BonusDistribution({
            accumulateNecessary: 300,
            amount: 5000e6
        });
        bonusesCount = 3;
        _locked = false;
    }

    function addCategory(bytes4 name, uint16 percentage, uint16 countDays, uint minDeposit, uint maxDeposit) external restricted onlyUnlocked {
        // require(getCategoryOrder(key) == 0, "MoneyBoxSettings: Category already exists");
        _categoriesCount++;
        _categoryConfig[_categoriesCount] = CategoryConfig({
            name: name,
            percentage: percentage,
            countDays: countDays,
            minDeposit: minDeposit,
            maxDeposit: maxDeposit,
            active: true
        });
        emit CategoryConfigAdded(msg.sender, _categoriesCount, name, percentage, countDays, minDeposit, maxDeposit);
    }

    function changeCategoryStatus(uint8 categoryId) external restricted onlyUnlocked {
        require(0 < categoryId && categoryId <= _categoriesCount, "MoneyBoxSettings: Category does not exist");
        _categoryConfig[categoryId].active = !_categoryConfig[categoryId].active;
        emit CategoryConfigUpdatedStatus(msg.sender, categoryId, _categoryConfig[categoryId].active);
    }

    function updateCategory(uint8 categoryId, bytes4 name, uint16 percentage, uint16 countDays, uint minDeposit, uint maxDeposit) external restricted onlyUnlocked {
        require(0 < categoryId && categoryId <= _categoriesCount, "MoneyBoxSettings: Category does not exist");
        require(_categoryConfig[categoryId].active, "MoneyBoxSettings: The Category is inactive");
        _categoryConfig[categoryId].name = name;
        _categoryConfig[categoryId].percentage = percentage;
        _categoryConfig[categoryId].countDays = countDays;
        _categoryConfig[categoryId].minDeposit = minDeposit;
        _categoryConfig[categoryId].maxDeposit = maxDeposit;
        emit CategoryConfigUpdated(msg.sender, categoryId, name, percentage, countDays, minDeposit, maxDeposit);
    }

    function getCountCategories() external view returns(uint8) {
        return _categoriesCount;
    }

    function getCategoryInfo(uint8 categoryId) public view returns(bytes4, uint16, uint16, uint, uint, bool) {
        require(0 < categoryId && categoryId <= _categoriesCount, "MoneyBoxSettings: Category does not exist");
        return (
            _categoryConfig[categoryId].name,
            _categoryConfig[categoryId].percentage,
            _categoryConfig[categoryId].countDays,
            _categoryConfig[categoryId].minDeposit,
            _categoryConfig[categoryId].maxDeposit,
            _categoryConfig[categoryId].active
        );
    }

    function addBonusDistribution(uint64 accumulateNecessary, uint amount) external restricted onlyUnlocked {
        require(bonusDistribution[bonusesCount].accumulateNecessary < accumulateNecessary);
        require(accumulateNecessary > 0 && amount > 0);
        bonusDistribution[++bonusesCount] = BonusDistribution({
            accumulateNecessary: accumulateNecessary, amount: amount
        });
        emit BonusDistributionAdded(msg.sender, bonusesCount, accumulateNecessary, amount);
    }

    function changeBonusDistribution(uint8 bonusDistributionId, uint64 accumulateNecessary, uint amount) external restricted onlyUnlocked {
        require(bonusDistributionId > 0 && bonusDistributionId <= bonusesCount);
        require(accumulateNecessary > 0 && amount > 0);
        bonusDistribution[bonusDistributionId] = BonusDistribution({
            accumulateNecessary: accumulateNecessary, amount: amount
        });
        emit BonusDistributionUpdated(msg.sender, bonusDistributionId, accumulateNecessary, amount);
    }

    function changeRegisterSettings(uint newRegisterPrice, uint newAmountForBonus) external restricted onlyUnlocked {
        require(newAmountForBonus <= newRegisterPrice, "[MoneyBoxSettings]: newAmountForBonus <= newRegisterPrice");
        registerPrice = newRegisterPrice;
        amountForBonus = newAmountForBonus;
        emit RegisterSettingsUpdated(msg.sender, registerPrice, amountForBonus);
    }

    function getLogicSettings() external view returns(uint, uint, uint8) {
        return (
            registerPrice,
            amountForBonus,
            bonusesCount
        );
    }

    function getBonusDistribution(uint8 id) external view returns(uint64, uint) {
        return (
            bonusDistribution[id].accumulateNecessary,
            bonusDistribution[id].amount
        );
    }

    function getBonusesCount() external view returns(uint8) {
        return bonusesCount;
    }
}
