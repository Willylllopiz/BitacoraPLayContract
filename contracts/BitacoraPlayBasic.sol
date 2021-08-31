pragma solidity ^0.6.2;

import "./IMoneyBox.sol";

abstract contract BitacoraPlayBasic {
    event SignUpEvent(address indexed _newUser, uint indexed _userId, address indexed _sponsor, uint _sponsorId);
    event CompletedBonusEvent(address indexed _user, uint _userId, uint8 indexed _range, uint8 indexed plan);
    event BonusAvailableToCollectEvent(address indexed _user, uint _userId, uint8 indexed _range, uint8 indexed plan);
    event NewUserChildEvent(address indexed _user, address indexed _sponsor);
    event AvailableBalanceForMoneyBox(address indexed _user, uint _amounnt);

    struct User {
        uint id;
        address wallet;
        address referrer;

        uint8 referRange;
        uint8 careerRange;

        ReferredPlan referredPlan;
        PendingBonus pendingBonus;
        CareerPlan careerPlan;

        uint256 activationDate;
    }

    struct ReferredPlan {
        uint accumulatedMembers; //Cantidad acumulada de pagos de hasta el quinto nivel
        uint accumulatedDirectMembers; //cantidad acumulada de referidos directos para uso de los bonos
        uint accumulatedPayments; //cantidad acumulada de pagos para la distribucion del bono actual del usuario
        uint accumulatedDirectReferralPayments; //cantidad acumulada de pagos directos de referidos para el pago del 60 %
    }

    struct CareerPlan {
        uint accumulatedDirectPlanCareer;
        uint accumulatedPlanCareer;
        bool activeCareerPlan;
    }

    struct RangeConfig {
        uint assetsDirect;
        uint assetsSameNetwork;
        uint8 qualifyingCycles;

        uint bonusValue;
        uint surplus;
        uint remainderVehicleBonus;
    }

    struct CareerRangeConfig {
        uint assetsDirect;
        uint assetsSameNetwork;
        uint bonusValue;
    }

    struct PendingBonus {
        uint moneyBox;
        uint adminBonus;
        uint himSelf;
    }

    uint8 public currentStartingLevel = 1;
    uint8 public constant ACTIVE_LEVEL = 5;
    uint public lastUserId = 2;
    uint public globalBalance = 0;

    // Referral Plan Payments
    uint public referralPlanPrice = 35e18;
    uint public referralDirectPayment = 18e18; //60% of referralPlanPrice.
    // CAreer Plan Payments
    uint public careerPlanPrice = 50e18;


    mapping(address => User) users;

    mapping(uint => address) internal idToAddress;

    mapping(uint => RangeConfig) internal rangeConfig;
    mapping(uint => CareerRangeConfig) internal careerRangeConfig;

    address public owner;
    address externalAddress;
    address rootAddress;
    IMoneyBox moneyBox;
}