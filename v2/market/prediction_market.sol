// SPDX-License-Identifier: GPL-3.0

import "../typing/interface.sol";
import "../typing/library.sol";
import "../lib/token.sol";

pragma solidity >=0.7.0 <0.9.0;

contract PredictionMarket {
    using MarketLib for mapping(address => MarketLib.T);
    using TopicLib for TopicLib.T[];
    using IssueLib for IssueLib.T;

    mapping(address => MarketLib.T) public market;
    TopicLib.T[] public topic;
    IssueLib.T public issue;

    PublicAccountManager public account;
    address public admin;
    string public name;
    string public symbol;
    uint public INITIAL_SUPPLY;

    constructor(address _account){
        admin = msg.sender;
        account = PublicAccountManager(_account);
        name = account.name();
        symbol = account.symbol();
        INITIAL_SUPPLY = account.INITIAL_SUPPLY();

        issue.init();
    }

    modifier adminOnly{
        require(msg.sender == admin, "admin only");
        _;
    }

    modifier hasMarket(address _market){
        require(market[_market].is_open && market[_market].is_active, "invalid market");
        _;
    }

    function balanceOf(address _address)
    external view returns (uint){
        return account.balanceOf(_address);
    }

    function totalSupply()
    external view returns (uint){
        return account.totalSupply();
    }

    function isFrozen(address _address)
    external view returns (uint){
        return account.isFrozen(_address);
    }

    function transfer(address _to, uint _value)
    public {
        account.transfer(msg.sender, _to, _value);
    }

    function burnToken(uint _value)
    public {
        account.burn(msg.sender, _value);
    }

    function freezeAccount(address _address, uint _timestamp)
    public adminOnly {
        account.freeze(_address, _timestamp);
    }

    function createTopic(string calldata _topic, string calldata _icon)
    public {
        topic.append(_topic, _icon);
    }

    function getTopicRange(uint _start)
    public view returns (TopicLib.T[10] memory){
        return topic.range(_start);
    }

    function freezeTopic(uint _index)
    public adminOnly {
        topic.freeze(_index);
    }


    function thawTopic(uint _index)
    public adminOnly {
        topic.thaw(_index);
    }

    function marketOpen(address _market)
    public view hasMarket(_market) returns (bool){
        return true;
    }

    function createMarket(address _market, string calldata _name)
    public adminOnly {
        market.create(_market, _name);
    }

    function openMarket(address _market)
    public adminOnly {
        market.open(_market);
    }

    function closeMarket(address _market)
    public adminOnly {
        market.close(_market);
    }

    function freezeMarket(address _market)
    public adminOnly {
        market.freeze(_market);
    }

    function thawMarket(address _market)
    public adminOnly {
        market.thaw(_market);
    }

    function initIssue(address _issue)
    public {
        issue.valid[_issue] = true;
    }

    function createIssue(address _issue, uint[3] calldata _time_pool_volume, uint _state, uint _topic, address _market)
    public {
        issue.create(_issue, _time_pool_volume, _state, _topic, _market);
    }

    function getIssueRange(address _cursor, uint _type, bool _reverse, uint _state, uint _topic, address _market, address _follower)
    public view returns (IssueLib.template[10] memory){
        return issue.range(_cursor, _type, _reverse, _state, _topic, _market, _follower);
    }
}
