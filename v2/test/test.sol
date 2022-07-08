// SPDX-License-Identifier: GPL-3.0


pragma solidity >=0.7.0 <0.9.0;

contract Test {
    mapping(uint=>info)test;
    struct info{
        uint test;
    }

    function set(uint _test) public {
        test[_test].test=1;
    }

    function get(uint _test) public view returns(uint){
        return test[_test].test;
    }
}
