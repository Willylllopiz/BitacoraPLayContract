pragma solidity ^0.5.10;
    
contract BitacoraPlay{
    event SignUpEvent(address indexed _newUser, uint indexed _userId, address indexed _sponsor, uint _sponsorId);
    event CompletedBonusEvent(address indexed _user, uint indexed _userId, Range indexed _range);
    event BonusAvailableToCollectEvent(address indexed _user, uint indexed _userId, Range indexed _range);
    event NewUserChildEvent(address indexed _user, address indexed _sponsor,  uint16 _position);
    
    
    enum Range {
        Rookie,
        Junior,
        Leader,
        Guru,
        GuruVehicle
    }
    
    struct User {
        uint id;
        address[] wallets;
        address referrer;
        Range referRange;
        address[] referrals;
        
        uint accumulatedMembers;
        uint accumulatedDirectMembers;
        uint accumulatedPayment;
        
        uint256 activationDate;
        
        uint withDrawl;
    }
    
    struct RangeConfig {
        uint activeAssets;
        uint assetsSameNetwork;
        uint8 qualifyingCycles;
        
        uint bonusValue;
        uint surplus;
        uint remainderVehicleBonus;
    }
    
    uint8 public currentStartingLevel = 1;
    uint8 public constant ACTIVE_LEVEL = 5;
    uint public lastUserId = 2;
    uint public refererPlanPrice = 100 trx;
    uint internal externalSurplus;
    
    
    mapping(address => User) public users;
    mapping(uint => address) internal idToAddress;
    mapping(uint8 => uint) public levelDistribution;
    mapping(uint => RangeConfig) internal rangeConfig;
    
    address public owner;
    address externalAddress;
    address rootAddress;
    
    modifier restricted() {
        require(msg.sender == owner, "restricted");
        _;
    }
    
    function getSurplus() external restricted view returns(uint){
        return externalSurplus;
    }
    
    function withdrawSurplus() public {
        require(msg.sender == owner, "onlyOwner");
        address(uint160(owner)).transfer(externalSurplus);
        externalSurplus = 0;
    }
    
    constructor(address _externalAddress, address _rootAddress) public {
        owner = msg.sender;
        initializeValues();
        
        externalAddress = _externalAddress;
        rootAddress = _rootAddress;
        users[rootAddress].id = 1;
        users[rootAddress].referrer = address(0);
        idToAddress[1] = rootAddress;
        users[_rootAddress].referRange = Range.Guru;
    }
    
    function initializeValues() internal {
        // levelDistribution[5] = 60; //
        externalSurplus = 0 trx;
        
        // Rookie Bonus Configuration
        rangeConfig[ uint(Range.Rookie) ] = RangeConfig({
            activeAssets: 0,
            assetsSameNetwork: 0,
            qualifyingCycles: 0,
            bonusValue: 0 trx,
            surplus: 0 trx,
            remainderVehicleBonus: 0 trx
        });
        // Junior Bonus Configuration
        rangeConfig [ uint(Range.Junior) ] = RangeConfig({
            activeAssets: 30,
            assetsSameNetwork: 3000,
            qualifyingCycles: 1,
            bonusValue: 500 trx,
            surplus: 40 trx, // TODO: en el documento dice que sobran 50 y son 40 revisar esto
            remainderVehicleBonus: 540 trx
            
        });
        // Leader Bonus Configuration
        rangeConfig[ uint(Range.Leader) ] = RangeConfig({
            activeAssets: 100,
            assetsSameNetwork: 7000,
            qualifyingCycles: 2,
            bonusValue: 1800 trx,
            surplus: 0 trx,
            remainderVehicleBonus: 3240 trx
        });
        // Guru Bonus Configuration
        rangeConfig[ uint(Range.Guru) ] = RangeConfig({
            activeAssets: 300,
            assetsSameNetwork: 20000,
            qualifyingCycles: 2,
            bonusValue: 4500 trx,
            surplus: 0 trx,
            remainderVehicleBonus: 9900 trx
        });
        // GuruVehicle Bonus Configuration
        rangeConfig[ uint(Range.GuruVehicle) ] = RangeConfig({
            activeAssets: 300,
            assetsSameNetwork: 20000,
            qualifyingCycles: 2,
            bonusValue: 0 trx,
            surplus: 0 trx,
            remainderVehicleBonus: 14400 trx
        });
    }
    
    function() external payable {
        require(msg.value == refererPlanPrice, "invalid registration cost");
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
    
    function payMonth(address _user) internal {
         require(isUserExists(_user), "user is not exists. Register first.");
         require( block.timestamp + 30 days >  users[_user].activationDate, "user already active this month.");
         users[_user].activationDate =  block.timestamp;
         updateActiveMembers(ACTIVE_LEVEL, users[_user].referrer);
    }
    
    function payMonthly() external payable {
        require(msg.value == refererPlanPrice, "invalid price");
        payMonth(msg.sender);
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
        users[userAddress].referRange = Range.Rookie;
       
        lastUserId++;
        
        users[userAddress].activationDate =  block.timestamp;
        updateActiveMembers(ACTIVE_LEVEL, referrerAddress);
        
        users[referrerAddress].referrals.push(userAddress);
        emit NewUserChildEvent(userAddress, referrerAddress, uint16(users[referrerAddress].referrals.length - 1));
        emit SignUpEvent(userAddress, users[userAddress].id, referrerAddress, users[referrerAddress].id);
        // repartir ganancias!!!!!!!!!!!!!
    }
    
    // Este metodo se debe verificar quien y como paga la inscripcion del nuevo usuario
    function signUpAdmin(address _user, address _sponsor) external restricted returns(string memory) {
        registration(_user, _sponsor);
            return "registration successful";
    }
    
    function signUp(address referrerAddress) external payable {
        require(msg.value == refererPlanPrice, "invalid registration cost");
        registration(msg.sender, referrerAddress);
    }
    
    function updateActiveMembers(uint8 _level, address _referrerAddress) private {
        if(_level > 0 && _referrerAddress != address(0)){
            users[_referrerAddress].accumulatedMembers ++;
            users[_referrerAddress].accumulatedPayment += 0.36 trx;
            if (checkRange(_referrerAddress, users[_referrerAddress].referRange)){
                emit CompletedBonusEvent(_referrerAddress, users[_referrerAddress].id, users[_referrerAddress].referRange);
                changeRange(_referrerAddress);
            }
            updateActiveMembers(_level - 1, users[_referrerAddress].referrer);
        }
        return;
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    
    function checkRange(address userAddress, Range _range) public view returns(bool){
        return users[userAddress].accumulatedMembers == (rangeConfig [ uint(_range)].assetsSameNetwork *
        rangeConfig [ uint(_range)].qualifyingCycles ) &&
        users[userAddress].accumulatedDirectMembers == rangeConfig [ uint(_range)].activeAssets;
    }
    
    function changeRange(address userAddress) private {
      //   Almacenar las ganancias del rango que esta dejando atras para su futura extraccion, cambia de rango y transforma las variables
      //   del usuario para el nuevo conteo del siguiente bono
      
      users[userAddress].withDrawl += rangeConfig[uint(users[userAddress].referRange)].bonusValue;
      users[userAddress].accumulatedPayment -= rangeConfig[uint(users[userAddress].referRange)].bonusValue;
      externalSurplus += rangeConfig[uint(users[userAddress].referRange)].surplus;
      emit BonusAvailableToCollectEvent(userAddress, users[userAddress].id, users[userAddress].referRange);
      
      
    // Updating number of assets of the same network
      users[userAddress].accumulatedMembers = users[userAddress].accumulatedMembers - rangeConfig[uint(users[userAddress].referRange)].assetsSameNetwork >=0 
      ? users[userAddress].accumulatedMembers - rangeConfig[uint(users[userAddress].referRange)].assetsSameNetwork
      : 0;
    // Updating number of direct assets
      users[userAddress].accumulatedDirectMembers = users[userAddress].accumulatedDirectMembers - rangeConfig[uint(users[userAddress].referRange)].activeAssets >=0 
      ? users[userAddress].accumulatedDirectMembers - rangeConfig[uint(users[userAddress].referRange)].activeAssets
      : 0;
    //  Updating Range
      users[userAddress].referRange =  users[userAddress].referRange == Range.Junior ? Range.Leader : 
      users[userAddress].referRange == Range.Leader ? Range.Guru : 
      users[userAddress].referRange == Range.Guru ? Range.GuruVehicle 
      : Range.Junior;
    }
}
