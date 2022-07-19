// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../typing/interface.sol";

contract BaseModifier{
    modifier positive(uint _value){
        require(_value>0,"need positive value");
        _;
    }

    modifier active(PrivateAccountManager _account,address _address){
        uint timestamp = _account.isFrozen(_address);
        if (timestamp != 0) {
            require(timestamp <= block.timestamp, "account banned");
        }
        _;
    }

    modifier tokenEnough(PrivateAccountManager _account,address _address, uint _value){
        require(_value>0,"need positive value");
        require(_account.balanceOf(_address) >= _value, "no enough token");
        uint timestamp = _account.isFrozen(_address);
        if (timestamp != 0) {
            require(timestamp <= block.timestamp, "account banned");
        }
        _;
    }
}