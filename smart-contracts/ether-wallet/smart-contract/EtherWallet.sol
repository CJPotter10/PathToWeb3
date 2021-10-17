// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract EtherWallet {
    address payable public owner;

    constructor(address payable _owner) {
        owner = _owner;
    }

    // Having the payable keyword allows for currency to be sent and does not need additional logic to implement
    function deposit() payable public {
    }

    // Sends money to another address
    function send(address payable to, uint _amount) public {
        if(msg.sender == owner) {
            to.transfer(_amount);
            return;
        }
        revert('sender is not allowed');
    }

    function balanceOf() view public returns(uint){
        return address(this).balance;
    }
}