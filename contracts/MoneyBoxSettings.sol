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
}
