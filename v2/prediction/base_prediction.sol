// SPDX-License-Identifier: GPL-3.0

import "../typing/interface.sol";
import "../typing/struct.sol";

pragma solidity >=0.7.0 <0.9.0;


contract BasePrediction {
    BasePredictionInfo public info;
    PrivateAccountManager account;

    address public owner;
    bool public settled;
    uint public init_amount;
    uint public option_num;

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
