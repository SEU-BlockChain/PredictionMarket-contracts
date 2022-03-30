// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./typing.sol";
import "./binary_prediction.sol";

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

    function admin() public view returns (address){
        return publicAccounts.admin();
    }

    function name() external view returns (string memory){
        return publicAccounts.name();
    }

    function symbol() external view returns (string memory){
        return publicAccounts.symbol();
    }

    function INITIAL_SUPPLY() external view returns (uint){
        return publicAccounts.INITIAL_SUPPLY();
    }

    function tokenOf(address _address) external view returns (uint){
        return publicAccounts.tokenOf(_address);
    }

    function totalToken() external view returns (uint){
        return publicAccounts.totalToken();
    }

    function isFrozen(address _address) external view returns (uint){
        return publicAccounts.isFrozen(_address);
    }

    function transferToken(address _to, uint _value) public {
        publicAccounts.transfer(msg.sender, _to, _value);
        emit TransferEvent(msg.sender, _to, _value);
    }

    function burnToken(uint _value) public {
        publicAccounts.burn(msg.sender, _value);
        emit BurnEvent(msg.sender, _value);
    }

    function frozeAccount(address _address, uint timestamp) public adminOnly {
        publicAccounts.froze(_address, timestamp);
        emit FrozeEvent(_address, timestamp);
    }
}

contract PredictionMarket is AccountProxy {
    struct Topic {
        address owner;
        string title;
        string icon;
        address[] predictions;
        uint startTime;
    }

    uint public topicNum;
    Topic[] topics;

    event CreateTopicEvent(address indexed owner, string indexed title);
    event CreateBinaryPredictionEvent(address indexed owner, address indexed p, string indexed desc);

    constructor(address _address){
        privateAccounts = PrivateAccounts(_address);
        publicAccounts = PublicAccounts(_address);
    }

    function createTopic(string memory title, string memory icon) external {
        address[] memory empty;
        topics.push(Topic(msg.sender, title, icon, empty, block.timestamp));
        topicNum++;
        emit CreateTopicEvent(msg.sender, title);
    }

    function topicInfo(uint i) external view returns (Topic memory info){
        info = topics[i];
    }

    function CreateBinaryPrediction(uint _topicId, PredictionInfo calldata _info, string[] calldata _desc) external {
        BinaryPrediction p = new BinaryPrediction(msg.sender, privateAccounts, _info, _desc);
        topics[_topicId].predictions.push(address(p));
        emit CreateBinaryPredictionEvent(msg.sender, address(p), _info.desc);
    }
}