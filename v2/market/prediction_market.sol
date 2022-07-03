// SPDX-License-Identifier: GPL-3.0

import "typing/interface.sol";
import "typing/type.sol";

pragma solidity >=0.7.0 <0.9.0;

contract AccountProxy {
    PrivateAccounts privateAccounts;
    PublicAccounts public publicAccounts;

    event TransferEvent(address indexed _from, address indexed _to, uint256 _value);
    event BurnEvent(address indexed _address, uint256 _value);
    event FrozeEvent(address indexed _address, uint _timestamp);

    modifier adminOnly{
        require(msg.sender == admin());
        _;
    }

    function admin() 
    public view returns (address){
        return publicAccounts.admin();
    }

    function name() 
    external view returns (string memory){
        return publicAccounts.name();
    }

    function symbol() 
    external view returns (string memory){
        return publicAccounts.symbol();
    }

    function INITIAL_SUPPLY() 
    external view returns (uint){
        return publicAccounts.INITIAL_SUPPLY();
    }

    function balanceOf(address _address) 
    external view returns (uint){
        return publicAccounts.balanceOf(_address);
    }

    function totalSupply() 
    external view returns (uint){
        return publicAccounts.totalSupply();
    }

    function isFrozen(address _address) 
    external view returns (uint){
        return publicAccounts.isFrozen(_address);
    }

    function transfer(address _to, uint _value) 
    public {
        publicAccounts.transfer(msg.sender, _to, _value);
        emit TransferEvent(msg.sender, _to, _value);
    }

    function burnToken(uint _value) 
    public {
        publicAccounts.burn(msg.sender, _value);
        emit BurnEvent(msg.sender, _value);
    }

    function frozeAccount(address _address, uint timestamp) 
    public adminOnly {
        publicAccounts.froze(_address, timestamp);
        emit FrozeEvent(_address, timestamp);
    }
}

contract IssueProxy{
    Issues issues;

}

contract PredictionMarket is AccountProxy,IssueProxy {
    constructor(address _account_address,address _issues_address){
        privateAccounts = PrivateAccounts(_account_address);
        publicAccounts = PublicAccounts(_account_address);
        issues=Issues(_issues_address);
    }
}
