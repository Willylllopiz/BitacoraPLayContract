pragma solidity ^0.5.10;

contract MoneyBox {
    function addToBalance(address _user, uint amount) external payable;
}

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
        
        uint accumulatedMembers; //Cantidad acumulada de miembros de hasta el quinto nivel
        uint accumulatedDirectMembers; //cantidad acumulada de referidos directos para uso de los bonos
        uint accumulatedPayments; //cantidad acumulada de pagos para la distribucion del bono actual del usuario
        uint accumulatedDirectReferralPayments; //cantidad acumulada de pagos directos de referidos para el pago del 60 % 
        
        uint256 activationDate;
        
        uint withDrawl;
    }
    
    struct RangeConfig {
        uint assetsDirect;
        uint assetsSameNetwork;
        uint8 qualifyingCycles;
        
        uint bonusValue;
        uint surplus;
        uint remainderVehicleBonus;
    }
    
    struct PendingBonus {
        address[] users;
        uint[] usersAmount;
        Range [] userRange;
    }
    PendingBonus pendingBonusBuilder;
    
    uint8 public currentStartingLevel = 1;
    uint8 public constant ACTIVE_LEVEL = 5;
    uint public lastUserId = 2;
    
    // Referral Plan Payments
    uint public referralPlanPrice = 35e18;
    uint public referralDirectPayment = 18e18; //60% of referralPlanPrice
    
    
    mapping(address => User) public users;
    mapping(uint => address) internal idToAddress;
    mapping(uint8 => uint) public levelDistribution;
    mapping(uint => RangeConfig) internal rangeConfig;
    
    address public owner;
    address externalAddress;
    address rootAddress;
    MoneyBox moneyBox;
    
    modifier restricted() {
        require(msg.sender == owner, "restricted");
        _;
    }
    
    function withdrawLostTRXFromBalance() public {
        require(msg.sender == owner, "onlyOwner");
        address(uint160(owner)).transfer(address(this).balance);
    }
    
    function withdrawBalanceOfReferredPlan () public {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(block.timestamp < users[msg.sender].activationDate, "user is not active, Pay membership.");
        require(users[msg.sender].accumulatedDirectReferralPayments > 100e18, "you do not have enough balance to withdraw.");
        address(uint160(msg.sender)).transfer(users[msg.sender].accumulatedDirectReferralPayments);
    }
    
    // function withDrawBonus () public{
    //     require(isUserExists(msg.sender), "user is not exists. Register first.");
    // }
    
    constructor(address _externalAddress, address _rootAddress, address _moneyBox) public {
        owner = msg.sender;
        initializeValues();

        moneyBox = MoneyBox(_moneyBox);
        
        externalAddress = _externalAddress;
        rootAddress = _rootAddress;
        users[rootAddress].id = 1;
        users[rootAddress].referrer = address(0);
        idToAddress[1] = rootAddress;
        users[_rootAddress].referRange = Range.Guru;
    }
    
    function initializeValues() internal {
        // Rookie Bonus Configuration
        rangeConfig[ uint(Range.Rookie) ] = RangeConfig({
            assetsDirect: 0,
            assetsSameNetwork: 0,
            qualifyingCycles: 0,
            bonusValue: 0e18,
            surplus: 0e18,
            remainderVehicleBonus: 0e18
        });
        // // Junior Bonus Configuration
        // rangeConfig [ uint(Range.Junior) ] = RangeConfig({
        //     assetsDirect: 30,
        //     assetsSameNetwork: 3000,
        //     qualifyingCycles: 1,
        //     bonusValue: 500e18,
        //     surplus: 40e18, // TODO: en el documento dice que sobran 50 y son 40 revisar esto
        //     remainderVehicleBonus: 540e18

        // });

        // Junior Bonus Configuration
        rangeConfig [ uint(Range.Junior) ] = RangeConfig({
                assetsDirect: 4,
                assetsSameNetwork: 10,
                qualifyingCycles: 1,
                bonusValue: 1.8e18,
                surplus: 0e18, // TODO: en el documento dice que sobran 50 y son 40 revisar esto
                remainderVehicleBonus: 1.8e18
        });
        // Leader Bonus Configuration
        rangeConfig[ uint(Range.Leader) ] = RangeConfig({
            assetsDirect: 100,
            assetsSameNetwork: 7000,
            qualifyingCycles: 2,
            bonusValue: 1800e18,
            surplus: 0e18,
            remainderVehicleBonus: 3240e18
        });
        // Guru Bonus Configuration
        rangeConfig[ uint(Range.Guru) ] = RangeConfig({
            assetsDirect: 300,
            assetsSameNetwork: 20000,
            qualifyingCycles: 2,
            bonusValue: 4500e18,
            surplus: 0e18,
            remainderVehicleBonus: 9900e18
        });
        // GuruVehicle Bonus Configuration
        rangeConfig[ uint(Range.GuruVehicle) ] = RangeConfig({
            assetsDirect: 300,
            assetsSameNetwork: 20000,
            qualifyingCycles: 2,
            bonusValue: 0e18,
            surplus: 0e18,
            remainderVehicleBonus: 14400e18
        });
    }
    
    function() external payable {
        require(msg.value == referralPlanPrice, "invalid registration cost");
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
    
    function payMonth(address _user) internal {
        require(isUserExists(_user), "user is not exists. Register first.");
        users[_user].activationDate =  block.timestamp + 30 days;
        users[users[_user].referrer].accumulatedDirectMembers ++;
        users[users[_user].referrer].accumulatedDirectReferralPayments += referralDirectPayment;
        users[users[_user].referrer].accumulatedMembers ++;
        users[users[_user].referrer].accumulatedPayments += 0.36e18;
        updateActiveMembers(ACTIVE_LEVEL, users[_user].referrer);
    }
    
    function payMonthly() external payable {
        require(msg.value == referralPlanPrice, "invalid price");
        require( block.timestamp <  users[msg.sender].activationDate, "user already active this month.");
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
        
        payMonth(userAddress);
        
        users[referrerAddress].referrals.push(userAddress);
        emit NewUserChildEvent(userAddress, referrerAddress, uint16(users[referrerAddress].referrals.length - 1));
        emit SignUpEvent(userAddress, users[userAddress].id, referrerAddress, users[referrerAddress].id);
        // repartir ganancias del plan carrera!!!!!!!!!!!!!
    }
    
    // Este metodo se debe verificar quien y como paga la inscripcion del nuevo usuario
    function signUpAdmin(address _user, address _sponsor) external restricted returns(string memory) {
        registration(_user, _sponsor);
            return "registration successful";
    }
    
    function signUp(address referrerAddress) external payable {
        require(msg.value == referralPlanPrice, "invalid registration cost");
        registration(msg.sender, referrerAddress);
    }
    
    function updateActiveMembers(uint8 _level, address _referrerAddress) private {
        if(_level > 0 && _referrerAddress != rootAddress){
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
        return users[ userAddress ].accumulatedMembers == (rangeConfig[ uint(_range)].assetsSameNetwork *
        rangeConfig[ uint(_range) ].qualifyingCycles ) &&
        users[ userAddress ].accumulatedDirectMembers == rangeConfig[ uint(_range) ].assetsDirect;
    }
    
    function changeRange(address userAddress) private {
      //   Almacenar las ganancias del rango que esta dejando atras 
      //   para su futura extraccion, cambia de rango y transforma las variables
      //   del usuario para el nuevo conteo del siguiente bono
      users[userAddress].accumulatedPayments -= rangeConfig[uint(users[userAddress].referRange)].bonusValue;
      if (users[userAddress].referRange == Range.Junior){
          moneyBox.addToBalance(userAddress, rangeConfig[uint(users[userAddress].referRange)].bonusValue); //si estamos en el rango junior se envia el bono al money box
      }
      else{
          pendingBonusBuilder.users.push( userAddress );
          pendingBonusBuilder.usersAmount.push( rangeConfig[ uint(users[ userAddress ].referRange) ].bonusValue);
          pendingBonusBuilder.userRange.push( users[userAddress].referRange );
      }
      users[rootAddress].withDrawl += rangeConfig[uint(users[userAddress].referRange)].surplus; //el excedente lo envio directo a la raiz o a la billetera externa preguntar y cambiar?????
      emit BonusAvailableToCollectEvent(userAddress, users[userAddress].id, users[userAddress].referRange);
      
    // Updating number of assets of the same network
      users[userAddress].accumulatedMembers = users[userAddress].accumulatedMembers - rangeConfig[uint(users[userAddress].referRange)].assetsSameNetwork >=0 
      ? users[userAddress].accumulatedMembers - rangeConfig[uint(users[userAddress].referRange)].assetsSameNetwork
      : 0;
    // Updating number of direct assets
      users[userAddress].accumulatedDirectMembers = users[userAddress].accumulatedDirectMembers - rangeConfig[uint(users[userAddress].referRange)].assetsDirect >=0 
      ? users[userAddress].accumulatedDirectMembers - rangeConfig[uint(users[userAddress].referRange)].assetsDirect
      : 0;
    //  Updating Range
      users[userAddress].referRange =  users[userAddress].referRange == Range.Junior ? Range.Leader : 
      users[userAddress].referRange == Range.Leader ? Range.Guru : 
      users[userAddress].referRange == Range.Guru ? Range.GuruVehicle 
      : Range.Junior;
    }
}
