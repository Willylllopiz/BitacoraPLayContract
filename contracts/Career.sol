pragma solidity ^0.6.2;
// SPDX-License-Identifier: MIT

import "./BitacoraPlayBasic.sol";
// import "./BitacoraPlaySettings.sol";
// import "./BitacoraPlay.sol";

contract Career is BitacoraPlayBasic{

    // BitacoraPlay bitacoraPlay;



    constructor(ITRC20 _depositTokenAddress, address _externalAddress, address _rootAddress, IMoneyBox _moneyBox, BitacoraPlaySettings _bitacoraPlaySettings /** ,BitacoraPlay _bitacoraPlay*/) public {
        depositToken = _depositTokenAddress;
        externalAddress = _externalAddress;
        rootAddress = _rootAddress;
        moneyBox=_moneyBox;
        bitacoraPlaySettings = _bitacoraPlaySettings;
        // bitacoraPlay = _bitacoraPlay;

    }

    function isActivatedCareerPlan(address _user) public view returns(bool) {
        // return users[_user].isActive;
        return true;
    }  

    // function activateCareerPlan() external{      
    //     require( bitacoraPlay.isActivatedMembership(msg.sender), "user is not active this month.");
    //     payCareerPlanActivation(msg.sender);
    // }

    // function payCareerPlanActivation(address _user) private {
    //     require(bitacoraPlay.isUserExists(_user), "user is not exists. Register first.");
    //     depositToken.safeTransferFrom(_user, address(this), careerPlanPrice);
    //     users[_user].careerPlan.activeCareerPlan = true;
    //     users[users[_user].referrer].careerPlan.accumulatedDirectPlanCareer ++;
    //     updateActivePlanCareer(ACTIVE_LEVEL,users[_user].referrer);
    //     administrativeBalance +=10e18;
    //     emit AvailableAdministrativeBalance(10e18);
    //     globalBalance += careerPlanPrice;
    // }

    // function updateActivePlanCareer(uint8 _level, address _referrerAddress) private {
    //     if(_level > 0 && _referrerAddress != rootAddress) {
    //         users[_referrerAddress].careerPlan.accumulatedPlanCareer ++;
    //         if (checkCareerRange(_referrerAddress, users[_referrerAddress].careerRange)){
    //              if ( 3 > users[_referrerAddress].careerRange){
    //                  changeCareerRange(_referrerAddress);
    //              }
    //             else{
    //                  users[rootAddress].pendingBonus.himSelf += 3e18;
    //              }

    //             emit CompletedBonusEvent(_referrerAddress, users[_referrerAddress].id, users[_referrerAddress].careerRange, 1);                
    //         }
    //         updateActivePlanCareer(_level - 1, users[_referrerAddress].referrer);
    //     }
    //     return;
    // }

    //  // Check that a user (_userAddress) is in a specified range (_range) in Career Plan
    // function checkCareerRange(address _userAddress, uint8 _range) public view returns(bool) {
    //     (uint _assetsDirect, uint _assetsSameNetwork, , ) = bitacoraPlaySettings.getCareerConfigInfo(_range);
    //     return _range <= 1 ? users[ _userAddress ].careerPlan.accumulatedDirectPlanCareer >= _assetsDirect :
    //     users[ _userAddress ].careerPlan.accumulatedPlanCareer >= _assetsSameNetwork;
    // }

    // function changeCareerRange(address _userAddress) private {
    //     (uint _assetsDirect, uint _assetsSameNetwork, uint _bonusValue,) = bitacoraPlaySettings.getCareerConfigInfo(users[_userAddress].careerRange);
    //     if (users[ _userAddress ].careerRange <= 1 ){
    //         users[ _userAddress ].careerPlan.accumulatedDirectPlanCareer -= _assetsDirect;
    //         users[_userAddress].pendingBonus.adminBonus += _bonusValue;
    //         emit BonusAvailableToCollectEvent(_userAddress, users[_userAddress].id, users[_userAddress].careerRange, 1);
    //     }
    //     if (users[ _userAddress ].careerRange == 2 || users[ _userAddress ].careerRange == 3){
    //         users[ _userAddress ].careerPlan.accumulatedPlanCareer -= _assetsSameNetwork;
    //         users[_userAddress].pendingBonus.moneyBox += _bonusValue;
    //         emit AvailableBalanceForMoneyBox(_userAddress, _bonusValue);
    //     }
    //     emit CompletedBonusEvent(_userAddress, users[_userAddress].id,users[_userAddress].careerRange, 1);
    //     //  Updating CareerRange
    //     users[ _userAddress ].careerRange ++;
    // }
}