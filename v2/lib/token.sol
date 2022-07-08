// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract PredictionToken {
    address public admin;
    string public name = "PredictionToken";
    string public symbol = "PMB";
    uint public decimals = 0;
    uint public INITIAL_SUPPLY = 1e8;
    mapping(address => uint) public balanceOf;
    uint public totalSupply;
    mapping(address => uint) public isFrozen;

    event TransferEvent(address indexed _from, address indexed _to, uint256 _value);
    event BurnEvent(address indexed _address, uint256 _value);
    event FreezeEvent(address indexed _address, uint _timestamp);

    constructor(address _admin){
        totalSupply = INITIAL_SUPPLY;
        admin = _admin;
        balanceOf[_admin] = INITIAL_SUPPLY;
    }

    modifier positive(uint _value){
        require(_value > 0, "need positive value");
        _;
    }

    modifier adminOnly(){
        require(msg.sender == admin, "admin only");
        _;
    }
    modifier active(address _address){
        uint timestamp = isFrozen[_address];
        if (timestamp != 0) {
            require(timestamp <= block.timestamp, "account banned");
        }
        _;
    }

    modifier tokenEnough(address _address, uint _value){
        require(_value > 0, "need positive value");
        require(balanceOf[_address] >= _value, "no enough token");
        uint timestamp = isFrozen[_address];
        if (timestamp != 0) {
            require(timestamp <= block.timestamp, "account banned");
        }
        _;
    }

    function transfer(address _from, address _to, uint _value)
    external active(_to) tokenEnough(_from, _value) {
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit TransferEvent(_from, _to, _value);
    }

    function burn(address _address, uint _value)
    external tokenEnough(_address, _value) {
        balanceOf[_address] -= _value;
        totalSupply -= _value;
        emit BurnEvent(_address, _value);
    }

    function freeze(address _address, uint _timestamp)
    external adminOnly {
        isFrozen[_address] = _timestamp;
        emit FreezeEvent(_address, _timestamp);
    }

    function increaseToken(address _address, uint _value)
    external active(_address) positive(_value) {
        balanceOf[_address] += _value;
        totalSupply += _value;
    }

    function decreaseToken(address _address, uint _value)
    external active(_address) positive(_value) {
        balanceOf[_address] -= _value;
        totalSupply -= _value;
    }
}