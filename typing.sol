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

contract BasePrediction {
    PredictionInfo public info;
    PrivateAccounts accounts;

    address public owner;
    bool public settled;
    uint init_amount;
    uint option_num;

    modifier activated{
        require(info.start < block.timestamp, "prediction unopened");
        require(info.end > block.timestamp, "prediction closed");
        _;
    }

    modifier hasOpened{
        require(info.start < block.timestamp, "prediction unopened");
        _;
    }

    modifier notOpened{
        require(info.start > block.timestamp, "prediction opened");
        _;
    }

    modifier hasClosed{
        require(info.end < block.timestamp, "prediction unclosed");
        _;
    }

    modifier notClosed{
        require(info.end > block.timestamp, "prediction closed");
        _;
    }

    modifier hasSettled{
        require(settled == true, "prediction unsettled");
        _;
    }

    modifier notSettled{
        require(settled == false, "prediction settled");
        _;
    }

    modifier ownerOnly{
        require(msg.sender == owner, "owner only");
        _;
    }

    modifier notOwner{
        require(msg.sender != owner, "not owner");
        _;
    }
}

struct PredictionInfo {
    uint start;
    uint end;
    string desc;
    string icon;
}

