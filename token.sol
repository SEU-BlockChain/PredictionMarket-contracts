// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract PredictionToken {
    address public admin;
    string public name = "PredictionToken";
    string public symbol = "PMB";
    uint public decimals = 0;
    uint public INITIAL_SUPPLY = 100000000;
    mapping(address => uint) public balanceOf;
    uint public totalSupply;
    mapping(address => uint) public isFrozen;

    constructor(){
        totalSupply = INITIAL_SUPPLY;
        admin = msg.sender;
        balanceOf[msg.sender] = INITIAL_SUPPLY;
    }

    modifier active(address _address){
        uint timestamp = isFrozen[_address];
        if (timestamp != 0) {
            require(timestamp <= block.timestamp, "account banned");
        }
        _;
    }

    modifier tokenEnough(address _address, uint _value){
        require(balanceOf[_address] >= _value, "no enough token");
        _;
    }

    modifier positive(uint _value){
        require(_value > 0, "need positive value");
        _;
    }

    function transfer(address _from, address _to, uint _value) external active(_from) active(_to) positive(_value) tokenEnough(_from, _value) {
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
    }

    function burn(address _address, uint _value) external active(_address) positive(_value) tokenEnough(_address, _value) {
        balanceOf[_address] -= _value;
        totalSupply -= _value;
    }

    function froze(address _address, uint _timestamp) external {
        isFrozen[_address] = _timestamp;
    }

    function increaseToken(address _address, uint _value) external active(_address) positive(_value) {
        balanceOf[_address] += _value;
        totalSupply += _value;
    }

    function decreaseToken(address _address, uint _value) external active(_address) positive(_value) {
        balanceOf[_address] -= _value;
        totalSupply -= _value;
    }
}

