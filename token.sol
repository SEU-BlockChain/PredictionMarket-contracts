// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract PredictionToken {
    address public admin;
    string public name = "PredictionToken";
    string public symbol = "PMB";
    uint public INITIAL_SUPPLY = 123456789;
    mapping(address => uint) public tokenOf;
    uint public totalToken;
    mapping(address => uint) public isFrozen;

    constructor(){
        totalToken = INITIAL_SUPPLY;
        admin = msg.sender;
        tokenOf[msg.sender] = INITIAL_SUPPLY;
    }

    modifier active(address _address){
        uint timestamp = isFrozen[_address];
        if (timestamp != 0) {
            require(timestamp <= block.timestamp, "1");
        }
        _;
    }

    modifier tokenEnough(address _address, uint _value){
        require(tokenOf[_address] >= _value, "2");
        _;
    }

    modifier positive(uint _value){
        require(_value > 0, "3");
        _;
    }

    function transfer(address _from, address _to, uint _value) external active(_from) active(_to) positive(_value) tokenEnough(_from, _value) {
        tokenOf[_from] -= _value;
        tokenOf[_to] += _value;
    }

    function burn(address _address, uint _value) external active(_address) positive(_value) tokenEnough(_address, _value) {
        tokenOf[_address] -= _value;
        totalToken -= _value;
    }

    function froze(address _address, uint _timestamp) external {
        isFrozen[_address] = _timestamp;
    }

    function increaseToken(address _address, uint _value) external active(_address) positive(_value) {
        tokenOf[_address] += _value;
        totalToken += _value;
    }

    function decreaseToken(address _address, uint _value) external active(_address) positive(_value) {
        tokenOf[_address] -= _value;
        totalToken -= _value;
    }
}

