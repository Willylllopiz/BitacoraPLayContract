pragma solidity ^0.6.2;

import "./IMoneyBox.sol";

abstract contract BitacoraPlayBasic {
    event SignUpEvent(address indexed _newUser, uint indexed _userId, address indexed _sponsor, uint _sponsorId);
    event CompletedReferredBonusEvent(address indexed _user, uint indexed _userId, ReferredRange indexed _range);
    event CompletedCareerBonusEvent(address indexed _user, uint indexed _userId, CareerRange indexed _range);
    event BonusAvailableToCollectEvent(address indexed _user, uint indexed _userId, ReferredRange indexed _range);
    event NewUserChildEvent(address indexed _user, address indexed _sponsor);
    event AvailableBalanceForMoneyBox(address indexed _user, uint _amounnt);

    enum ReferredRange {
        Rookie,
        Junior,
        Leader,
        Guru,
        GuruVehicle
    }

    enum CareerRange {
        AcademicPromoter,
        AcademicLeader,
        AcademicCommunity,
        Perseverance
    }

    struct User {
        uint id;
        address wallet;
        address referrer;

        ReferredRange referRange;
        CareerRange careerRange;

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
    uint public referralDirectPayment = 18e18; //60% of referralPlanPrice


    mapping(address => User) users;

    mapping(uint => address) internal idToAddress;

    mapping(uint => RangeConfig) internal rangeConfig;
    mapping(uint => uint) internal careerRangeConfig;

    address public owner;
    address externalAddress;
    address rootAddress;
    IMoneyBox moneyBox;

    // function getUserInfo() view public returns(uint id, address memory referrer) {
    //     return {
    //         id =
    //     }
    // }
}