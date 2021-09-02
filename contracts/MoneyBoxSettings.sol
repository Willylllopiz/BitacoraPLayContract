pragma solidity ^0.6.2;

import "./SettingsBasic.sol";
import "./IMoneyBoxSettings.sol";

contract MoneyBoxSettings is SettingsBasic, IMoneyBoxSettings {
    event CategoryConfigAdded(address indexed admin, uint8 categoryId, bytes4 name, uint16 percentage, uint16 countDays, uint minDeposit, uint maxDeposit);
    event CategoryConfigDeleted(address indexed admin, uint8 categoryId);
    event CategoryConfigUpdated(address indexed admin, uint8 categoryId, bytes4 name, uint16 percentage, uint16 countDays, uint minDeposit, uint maxDeposit);
    
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

    struct LogicSettings {
        uint registerPrice;
        uint amountForBonus;
        mapping(uint8 => BonusDistribution) bonusDistribution;
        uint8 bonusesCount;
    }

    struct BonusDistribution {
        uint64 accumulateNecessary;
        uint amount;
    }

    LogicSettings public _logicSettings;

    constructor(ITRC20 _depositTokenAddress) public {
        _initialize(msg.sender, _depositTokenAddress);
    }

    function _initialize(address _owner, ITRC20 _depositTokenAddress) private {
        _initializeSettingsBasic(_owner, _depositTokenAddress);
        _categoriesCount = 3;
        _categoryConfig[1] = CategoryConfig({
            name: "M3",
            percentage: 112,
            countDays: 90,
            minDeposit: 10e18,
            maxDeposit: 10000e18,
            active: true
        });
        _categoryConfig[2] = CategoryConfig({
            name: "M6",
            percentage: 142,
            countDays: 180,
            minDeposit: 10e18,
            maxDeposit: 10000e18,
            active: true
        });
        _categoryConfig[3] = CategoryConfig({
            name: "M12",
            percentage: 244,
            countDays: 360,
            minDeposit: 10e18,
            maxDeposit: 10000e18,
            active: true
        });
        
        _logicSettings.registerPrice = 50e18;
        _logicSettings.amountForBonus = 40e18;
        _logicSettings.bonusDistribution[1] = BonusDistribution({
            accumulateNecessary: 30,
            amount: 1000e18
        });
        _logicSettings.bonusDistribution[2] = BonusDistribution({
            accumulateNecessary: 100,
            amount: 1750e18
        });
        _logicSettings.bonusDistribution[3] = BonusDistribution({
            accumulateNecessary: 300,
            amount: 5000e18
        });
        _logicSettings.bonusesCount = 3;
    }

    function addCategory(bytes4 name, uint16 percentage, uint16 countDays, uint minDeposit, uint maxDeposit) override(IMoneyBoxSettings) external restricted {
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

    function deleteCategory(uint8 categoryId) override(IMoneyBoxSettings) external restricted {
        require(0 < categoryId && categoryId <= _categoriesCount, "MoneyBoxSettings: Category does not exist");
        require(_categoryConfig[categoryId].active, "MoneyBoxSettings: Category does not exist");
        _categoryConfig[categoryId].active = false;
        emit CategoryConfigDeleted(msg.sender, categoryId);
    }

    function updateCategory(uint8 categoryId, bytes4 name, uint16 percentage, uint16 countDays, uint minDeposit, uint maxDeposit) override(IMoneyBoxSettings) external restricted {
        require(0 < categoryId && categoryId <= _categoriesCount, "MoneyBoxSettings: Category does not exist");
        _categoryConfig[categoryId].name = name;
        _categoryConfig[categoryId].percentage = percentage;
        _categoryConfig[categoryId].countDays = countDays;
        _categoryConfig[categoryId].minDeposit = minDeposit;
        _categoryConfig[categoryId].maxDeposit = maxDeposit;
        emit CategoryConfigUpdated(msg.sender, categoryId, name, percentage, countDays, minDeposit, maxDeposit);
    }

    function getCategoryInfo(uint8 categoryId) override(IMoneyBoxSettings) public view returns(bytes4, uint16, uint16, uint, uint) {
        require(0 < categoryId && categoryId <= _categoriesCount, "MoneyBoxSettings: Category does not exist");
        return (
            _categoryConfig[categoryId].name,
            _categoryConfig[categoryId].percentage,
            _categoryConfig[categoryId].countDays,
            _categoryConfig[categoryId].minDeposit,
            _categoryConfig[categoryId].maxDeposit
        );
    }

    function addBonusDistribution(uint64 accumulateNecessary, uint amount) external {
        require(_logicSettings.bonusDistribution[_logicSettings.bonusesCount].accumulateNecessary < accumulateNecessary);
        require(accumulateNecessary > 0 && amount > 0);
        _logicSettings.bonusDistribution[++_logicSettings.bonusesCount] = BonusDistribution({
            accumulateNecessary: accumulateNecessary, amount: amount
        });
    }

    function changeBonusDistribution(uint8 bonusDistributionId, uint64 accumulateNecessary, uint amount) external {
        require(bonusDistributionId > 0 && bonusDistributionId <= _logicSettings.bonusesCount);
        require(accumulateNecessary > 0 && amount > 0);
        _logicSettings.bonusDistribution[bonusDistributionId] = BonusDistribution({
            accumulateNecessary: accumulateNecessary, amount: amount
        });
    }

    function getLogicSettings() override(IMoneyBoxSettings) external view returns(uint, uint, uint8) {
        return (
            _logicSettings.registerPrice,
            _logicSettings.amountForBonus,
            _logicSettings.bonusesCount
        );
    }

    function getBonusDistribution(uint8 id) override(IMoneyBoxSettings) external view returns(uint64, uint) {
        return (
            _logicSettings.bonusDistribution[id].accumulateNecessary,
            _logicSettings.bonusDistribution[id].amount
        );
    }
}
