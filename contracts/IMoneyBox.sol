pragma solidity ^0.6.2;

interface IMoneyBox {
    function depositFounds(uint8 _categoryId, address _user,uint _amount) external returns(bool);
}
