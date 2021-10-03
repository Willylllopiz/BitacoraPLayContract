pragma solidity ^0.6.2;

import "./CommonBasic.sol";

contract SettingsBasic is CommonBasic {
    event AdminAdded(address indexed _emitterAdmin, address indexed _addedAdmin, uint8 _adminId);
    event AdminActivated(address indexed _emitterAdmin, address indexed _addedAdmin, uint8 _adminId);
    event AdminDisabled(address indexed _emitterAdmin, address indexed _deletedAdmin, uint8 _adminId);
    event CommonSettingsUpdated(address indexed admin, uint8 minAllowedAdmins, uint8 maxAllowedAdmins, uint maxAmountToWithdraw, uint minAmountToWithdraw);
    
    struct Admin {
        uint8 id;
        bool active;
    }

    uint8 public adminsActives;
    uint8 public nextAdminId;
    mapping(address => Admin) public admins;
    mapping(uint8 => address) public idToAdmin;

    CommonSettings public _commonSettings;

    struct CommonSettings {
        uint8 minAllowedAdmins;
        uint8 maxAllowedAdmins;
        uint maxAmountToWithdraw;
        uint minAmountToWithdraw;
    }

    modifier restricted() {
        require(!_locked || msg.sender == _owner, "SettingsBasic: locked");
        require(isAdmin(msg.sender), "SettingsBasic: only admins");
        _;
    }

    modifier restrictedWithdrawLostTokens() override {
        require(isAdmin(msg.sender), "SettingsBasic: only admins");
        _;
    }

    function addAdmin(address user) external restricted returns(bool) {
        require(!isAdmin(user), 'SettingsBasic: The address is already admin');
        require(adminsActives < _commonSettings.maxAllowedAdmins, 'SettingsBasic: Validation max administrators allowed');
        adminsActives++;
        if(admins[user].id > 0) {
            Admin storage adminInfo = admins[user];
            adminInfo.active = true;
            emit AdminActivated(msg.sender, user, adminInfo.id);
        }
        else {
            admins[user] = Admin({
                id: nextAdminId,
                active: true
            });
            idToAdmin[nextAdminId] = user;
            nextAdminId++;
            emit AdminAdded(msg.sender, user, admins[user].id);
        }
        return true;
    }

    function deleteAdmin(address user) external restricted returns(bool) {
        require(isAdmin(user), "SettingsBasic: The address isn't admin");
        require(adminsActives > _commonSettings.minAllowedAdmins, 'SettingsBasic: Validation min administrators allowed');
        adminsActives--;
        Admin storage adminInfo = admins[user];
        adminInfo.active = false;
        emit AdminDisabled(msg.sender, user, adminInfo.id);
        return true;
    }

    function getAllAdmins() external view restricted returns(address[] memory) {
        address[] memory result = new address[](nextAdminId-1);
        for(uint8 id = 1; id < nextAdminId;id++) {
            result[id-1] = idToAdmin[id];
        }
        return result;
    }

    function getActiveAdmins() external view restricted returns(address[] memory) {
        address[] memory result = new address[](adminsActives);
        uint8 activeId;
        for(uint8 id = 1; id < nextAdminId; id++) {
            if(isAdmin(idToAdmin[id]))
                result[activeId++] = idToAdmin[id];
        }
        return result;
    }

    function isAdmin(address user) public view returns(bool) {
        return admins[user].active;
    }

    function _initializeSettingsBasic(ITRC20 _depositTokenAddress) internal {
        depositToken = _depositTokenAddress;
        admins[_owner] = Admin({
            id: 1,
            active: true
        });
        idToAdmin[1] = _owner;
        nextAdminId = 2;
        adminsActives = 1;
        _commonSettings = CommonSettings({
            minAllowedAdmins: 1,
            maxAllowedAdmins: 5,
            maxAmountToWithdraw: 1000000e6,
            minAmountToWithdraw: 10e6
        });
    }

    function setCommonSettings(uint8 minAllowedAdmins, uint8 maxAllowedAdmins, uint maxAmountToWithdraw, uint minAmountToWithdraw) external restricted {
        require(minAllowedAdmins > 0 && minAmountToWithdraw > 0);
        _commonSettings.minAllowedAdmins = minAllowedAdmins;
        _commonSettings.maxAllowedAdmins = maxAllowedAdmins;
        _commonSettings.minAmountToWithdraw = minAmountToWithdraw;
        _commonSettings.maxAmountToWithdraw = maxAmountToWithdraw;
        emit CommonSettingsUpdated(msg.sender, minAllowedAdmins, maxAllowedAdmins, maxAmountToWithdraw, minAmountToWithdraw);
    }

    function getCommonSettings() external view restricted returns(uint8, uint8, uint, uint) {
        return (
            _commonSettings.minAllowedAdmins,
            _commonSettings.maxAllowedAdmins,
            _commonSettings.minAmountToWithdraw,
            _commonSettings.maxAmountToWithdraw
        );
    }

}
