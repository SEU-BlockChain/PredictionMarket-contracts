// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

library IssuesLib {
    using IssuesLib for IssuesLib.T;

    struct T {
        uint length;
        mapping(address => _info) data;
        address[] by_time;
        address[] by_pool;
        address[] by_volume;
    }

    struct _info {
        uint _o_time;
        uint _o_pool;
        uint _o_volume;
        uint _f_state;
        uint _f_topic;
        mapping(address => bool) _f_followed;
    }

    function add() public{
        
    }
}
