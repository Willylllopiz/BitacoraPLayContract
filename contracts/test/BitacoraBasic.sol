pragma solidity ^0.6.2;

contract BitacoraBasic {
    struct User {
        uint id;
        address sponsor;
    }

    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    uint public nextUserId;
    address public root;

    constructor() public {
        root = msg.sender;
        users[root].id = 1;
        idToAddress[1] = root;
        nextUserId = 2;
    }

    function register(address sponsor) external {
        _register(msg.sender, sponsor);
    }

    function registerFor(address user, address sponsor) external {
        require(msg.sender == root, "Only owner");
        _register(user, sponsor);
    }

    function _register(address user, address sponsor) private {
        require(!isUserExists(user), "user exists");
        require(isUserExists(sponsor), "sponsor not exists");
        User memory _userInfo = User({
            id: nextUserId,
            sponsor: sponsor
        });
        users[user] = _userInfo;
        idToAddress[nextUserId] = user;
        nextUserId++;
    }

    function isUserExists(address user) public view returns (bool) {
        return users[user].id > 0;
    }
    function getUserInfo(address user) external view returns (uint, address, bool) {
        return (users[user].id, users[user].sponsor, users[user].id > 0);
    }

}