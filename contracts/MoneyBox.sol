pragma solidity ^0.6.2;

import "./CommonBasic.sol";

interface IBitacoraPlay {
    struct User {
        uint id;
        address[] wallets;
        uint moneyBox;
    }

    mapping(address => User) public users;

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function isUserExists(address user) public view returns (bool);
}

contract MoneyBox is CommonBasic{
    constructor(ITRC20 _depositTokenAddress) public {
        _initializeCommonBasic(msg.sender, _depositTokenAddress);
    }
}
