// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface PublicAccounts {
    function admin() external view returns (address);

    function name() external view returns (string calldata);

    function symbol() external view returns (string calldata);

    function INITIAL_SUPPLY() external view returns (uint);

    function tokenOf(address) external view returns (uint);

    function totalToken() external view returns (uint);

    function isFrozen(address) external view returns (uint);

    function transfer(address, address, uint) external;

    function burn(address, uint) external;

    function froze(address, uint) external;
}

interface PrivateAccounts is PublicAccounts {
    function increaseToken(address, uint) external;

    function decreaseToken(address, uint) external;
}


    struct PredictionInfo {
        uint start;
        uint end;
        string desc;
    }

contract BasePrediction {
    PredictionInfo public info;
    PrivateAccounts accounts;
    address public owner;
    bool public settled;

    modifier active{
        require(info.start < block.timestamp, "4");
        require(info.end > block.timestamp, "5");
        require(settled == false);
        _;
    }

    modifier notClosed{
        require(info.end > block.timestamp, "6");
        _;
    }

    modifier closed{
        require(info.end < block.timestamp, "6");
        _;
    }

    modifier ownerOnly{
        require(msg.sender == owner, "6");
        _;
    }

    modifier shareLimt(uint share){
        require(share >= 100);
        _;
    }

    modifier amountLimt(uint amount){
        require(amount >= 100);
        _;
    }
}