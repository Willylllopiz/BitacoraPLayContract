pragma solidity ^0.6.2;
// SPDX-License-Identifier: MIT

interface IMoneyBox {
    function depositFoundsFromBitacora(address user, uint8 categoryId, uint amount) external;
}
