pragma solidity ^0.5.10;

contract BitacoraPlay{
    event SignUpEvent(address indexed _newUser, uint indexed _userId, address indexed _sponsor, uint _sponsorId);
    
    enum Range { 
        Rookie,
        Junior,
        Leader,
        Guru
    }
    
    struct User {
        uint id;
        address referrer;
        Range referPlan;
        address[] referrals;
        uint256 inscriptionDate;
        uint256 activationDate;//revisar la activacion debe ser segun el plan o algo asi
    }
    
    uint public lastUserId = 2;
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    
    address public owner;
    address externalAddress;
    address rootAddress;
    
    modifier restricted() {
        require(msg.sender == owner, "restricted");
        _;
    }
    
    constructor(address _externalAddress, address _rootAddress) public {
        owner = msg.sender;
        externalAddress = _externalAddress;
        rootAddress = _rootAddress;
        // initializeValues();

        users[rootAddress].id = 1;
        users[rootAddress].referrer = address(0);
        idToAddress[1] = rootAddress;
    }

    function() external payable {
        require(msg.value == 5000000000000, "invalid registration cost");
        if(msg.data.length == 0) {
            return registration(msg.sender, rootAddress);
        }
        registration(msg.sender, bytesToAddress(msg.data));
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function withdrawLostTRXFromBalance() public {
        require(msg.sender == owner, "onlyOwner");
        address(uint160(owner)).transfer(address(this).balance);
    }
        
    function registration(address userAddress, address referrerAddress) private {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");

        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        idToAddress[lastUserId] = userAddress;
        users[userAddress].id = lastUserId;
        users[userAddress].referrer = referrerAddress;
        users[userAddress].referPlan = Range.Rookie;
        
        lastUserId++;
        
        users[referrerAddress].referrals.push(userAddress);
        users[referrerAddress].inscriptionDate = now;
        users[referrerAddress].activationDate = now;
        
        emit SignUpEvent(userAddress, users[userAddress].id, referrerAddress, users[referrerAddress].id);
        // repartir ganancias!!!!!!!!!!!!!
        
     }

    function signUpAdmin(address _user, address _sponsor) external restricted returns(string memory) {
        registration(_user, _sponsor);
        return "registration successful";
    }
     
    function signUp(address referrerAddress) external payable {
        require(msg.value == 5000000000000, "invalid registration cost");
        registration(msg.sender, referrerAddress);
    }
    
    // function updateActivemembers(uint _level, address _referrerAddress) private {
    //     if(_level > 0 && _referrerAddress != rootAddress && _referrerAddress != address(0)){
    //         users[_referrerAddress].activeMembers +=1;
    //         updateActivemembers(_level-=1, users[_referrerAddress].referrer);
    //     }
    // }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

}


