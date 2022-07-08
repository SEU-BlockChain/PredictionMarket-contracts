// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface PublicAccountManager {
    function admin() external view returns (address);

    function name() external view returns (string calldata);

    function symbol() external view returns (string calldata);

    function INITIAL_SUPPLY() external view returns (uint);

    function balanceOf(address) external view returns (uint);

    function totalSupply() external view returns (uint);

    function isFrozen(address) external view returns (uint);

    function transfer(address, address, uint) external;

    function burn(address, uint) external;

    function freeze(address, uint) external;
}

interface PrivateAccountManager is PublicAccountManager {
    function increaseToken(address, uint) external;

    function decreaseToken(address, uint) external;
}

interface PrivateIssueManager{
    
}