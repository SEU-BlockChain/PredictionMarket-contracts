// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface PublicAccounts {
    function admin() external view returns (address);

    function name() external view returns (string calldata);

    function symbol() external view returns (string calldata);

    function INITIAL_SUPPLY() external view returns (uint);

    function balanceOf(address) external view returns (uint);

    function totalSupply() external view returns (uint);

    function isFrozen(address) external view returns (uint);

    function transfer(address, address, uint) external;

    function burn(address, uint) external;

    function froze(address, uint) external;
}

interface PrivateAccounts is PublicAccounts {
    function increaseToken(address, uint) external;

    function decreaseToken(address, uint) external;
}

contract BaseModifier{
    modifier positive(uint _value){
        require(_value>0,"need positive value");
        _;
    }

    modifier active(PrivateAccounts _accounts,address _address){
        uint timestamp = _accounts.isFrozen(_address);
        if (timestamp != 0) {
            require(timestamp <= block.timestamp, "account banned");
        }
        _;
    }

    modifier tokenEnough(PrivateAccounts _accounts,address _address, uint _value){
        require(_value>0,"need positive value");
        require(_accounts.balanceOf(_address) >= _value, "no enough token");
        uint timestamp = _accounts.isFrozen(_address);
        if (timestamp != 0) {
            require(timestamp <= block.timestamp, "account banned");
        }
        _;
    }
}