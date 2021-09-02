pragma solidity ^0.6.2;

import "./ISettingsBasic.sol";
import "./CommonBasic.sol";

contract SettingsBasic is CommonBasic, ISettingsBasic {
    struct Admin {
        uint8 id;
        bool active;
    }

    uint8 public adminsActives;
    uint8 nextAdminId;
    mapping(address => Admin) admins;
    mapping(uint8 => address) idToAdmin;

    CommonSettings _commonSettings;

    struct CommonSettings {
        uint8 minAllowedAdmins;
        uint8 maxAllowedAdmins;
        uint maxAmountToWithdraw;
        uint minAmountToWithdraw;
    }

    modifier restricted() {
        require(isAdmin(msg.sender), "SettingsBasic: only admins");
        _;
    }

    modifier restrictedWithdrawLostTokens() override {
        require(isAdmin(msg.sender), "SettingsBasic: only admins");
        _;
    }

    function addAdmin(address user) external override restricted returns(bool) {
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

    function deleteAdmin(address user) external override restricted returns(bool) {
        require(isAdmin(user), "SettingsBasic: The address isn't admin");
        require(adminsActives > _commonSettings.minAllowedAdmins, 'SettingsBasic: Validation min administrators allowed');
        adminsActives--;
        Admin storage adminInfo = admins[user];
        adminInfo.active = false;
        emit AdminDisabled(msg.sender, user, adminInfo.id);
        return true;
    }

    function getAllAdmins() external override view restricted returns(address[] memory) {
        address[] memory result = new address[](nextAdminId-1);
        for(uint8 id = 1; id < nextAdminId;id++) {
            result[id-1] = idToAdmin[id];
        }
        return result;
    }

    function getActiveAdmins() external override view restricted returns(address[] memory) {
        address[] memory result = new address[](adminsActives);
        uint8 activeId;
        for(uint8 id = 1; id < nextAdminId; id++) {
            if(isAdmin(idToAdmin[id]))
                result[activeId++] = idToAdmin[id];
        }
        return result;
    }

    function isAdmin(address user) public override view returns(bool) {
        return admins[user].active;
    }

    function _initializeSettingsBasic(address _owner, ITRC20 _depositTokenAddress) internal {
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
            maxAmountToWithdraw: 1000000e18,
            minAmountToWithdraw: 10e18
        });
    }
}
