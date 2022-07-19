// SPDX-License-Identifier: GPL-3.0

import "../typing/interface.sol";

pragma solidity >=0.7.0 <0.9.0;


contract SEUBFaucet {
    mapping(address=>mapping(uint=>bool)) record;
    
    function add() 
    public payable{
        payable(address(this)).transfer(msg.value);
    }

    function get()
    public payable{
        uint time=block.timestamp%86400;
        require(!record[msg.sender][time],"-1");
        payable(msg.sender).transfer(1 ether);
        record[msg.sender][time]=true;
    }

    fallback() external  payable {}

    receive()external  payable {}
}

contract PMBFaucet {
    mapping(address=>mapping(uint=>bool)) record;
    PrivateAccountManager account;

    constructor(address _account){
        account=PrivateAccountManager(_account);
    }

    function get()
    public{
        uint time=block.timestamp%86400;
        require(!record[msg.sender][time],"-1");
        account.increaseToken(msg.sender,1000);
        record[msg.sender][time]=true;
    }
}