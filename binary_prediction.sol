// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./typing.sol";

contract BinaryPrediction is BasePrediction {
    string topic;

    struct BinaryOption {
        uint share;
        string desc;
    }

    BinaryOption[2] public options;

    mapping(address => mapping(uint => uint)) public shareOf;
    address[] public shareOfSlice;
    mapping(address => bool) public shareOfMapping;
    uint public totalShare;

    mapping(address => uint) public poolOf;
    address[] public poolOfSlice;
    mapping(address => bool) public  poolOfMapping;
    uint public totalPool;

    uint public equity;

    event LongOptionEvent(address indexed user, uint indexed optionId, uint amount, uint share);
    event ShortOptionEvent(address indexed user, uint indexed optionId, uint amount, uint share);
    event LongPoolEvent(address indexed user, uint amount);
    event ShortPoolEvent(address indexed user, uint amount);
    event ShareChangeEvent(uint timestamp, uint option0, uint option1);

    constructor(address _owner, PrivateAccounts _accounts, string memory _topic, PredictionInfo memory _info, string[2] memory _options){
        topic = _topic;
        owner = _owner;
        accounts = _accounts;
        info = _info;
        totalShare = 100;
        for (uint i = 0; i < 2; i++) {
            options[i] = BinaryOption(50, _options[i]);
        }
    }

    modifier shareEnough(uint _optionId, uint _share){
        require(shareOf[msg.sender][_optionId] >= _share, "insufficient share");
        _;
    }

    modifier poolEnough(uint _amount){
        require(poolOf[msg.sender] >= _amount, "insufficient pool");
        _;
    }

    function _allocate(uint _optionId, uint _amount) internal view returns (uint share){
        uint Ni = options[_optionId].share;
        share = _amount * totalShare / (Ni + _amount * _amount * _amount * (totalShare - Ni) / ((_amount + Ni) * (_amount + totalShare) * (_amount + totalPool)));
    }

    function _withdraw(uint _optionId, uint _share) internal view returns (uint amount){
        amount = _share * (options[_optionId].share - _share) / (totalShare - _share);
    }

    function _divide(address _address) internal view returns (uint amount){
        amount = equity * poolOf[_address] / totalPool;
    }

    function getInfo() external view returns (PredictionInfo memory _info, BinaryOption[2] memory _options, address _owner, string memory _topic, uint _totalShare, uint _totalPool, uint _equity){
        _info = info;
        _options = options;
        _owner = owner;
        _topic = topic;
        _totalShare = totalShare;
        _totalPool = totalPool;
        _equity = equity;
    }

    function longOptionEstimate(uint _optionId, uint _amount) external view active amountLimit(_amount) returns (uint share){
        share = _allocate(_optionId, _amount - _amount * 3 / 100);
    }

    function shortOptionEstimate(uint _optionId, uint _share) external view active shareLimit(_share) returns (uint amount){
        amount = _withdraw(_optionId, _share);
    }

    function equityEstimate(address _address) external view returns (uint amount){
        amount = _divide(_address);
    }

    function longOption(uint _optionId, uint _amount) external active amountLimit(_amount) {
        uint equityFee = _amount * 3 / 100;
        accounts.decreaseToken(msg.sender, _amount);
        uint share = _allocate(_optionId, _amount - equityFee);
        options[_optionId].share += share;
        if (!shareOfMapping[msg.sender]) {
            shareOfMapping[msg.sender] = true;
            shareOfSlice.push(msg.sender);
        }
        shareOf[msg.sender][_optionId] += share;
        totalShare += share;
        equity += equityFee;
        emit LongOptionEvent(msg.sender, _optionId, _amount, share);
        emit ShareChangeEvent(block.timestamp, options[0].share, options[1].share);
    }

    function shortOption(uint _optionId, uint _share) external active shareLimit(_share) shareEnough(_optionId, _share) {
        uint amount = _withdraw(_optionId, _share);
        shareOf[msg.sender][_optionId] -= _share;
        totalShare -= _share;
        options[_optionId].share -= _share;
        accounts.increaseToken(msg.sender, amount);
        emit ShortOptionEvent(msg.sender, _optionId, amount, _share);
        emit ShareChangeEvent(block.timestamp, options[0].share, options[1].share);
    }

    function longPool(uint _amount) external active {
        accounts.decreaseToken(msg.sender, _amount);
        totalPool += _amount;
        poolOf[msg.sender] += _amount;
        if (!poolOfMapping[msg.sender]) {
            poolOfMapping[msg.sender] = true;
            poolOfSlice.push(msg.sender);
        }
        emit LongPoolEvent(msg.sender, _amount);
    }

    function shortPool(uint _amount) external active poolEnough(_amount) {
        accounts.increaseToken(msg.sender, _amount);
        totalPool -= _amount;
        poolOf[msg.sender] -= _amount;
        emit ShortPoolEvent(msg.sender, _amount);
    }

    function settle(uint _optionId) external ownerOnly hasClosed notSettled {
        for (uint i = 0; i < shareOfSlice.length; i++) {
            address shareHolder = shareOfSlice[i];
            accounts.increaseToken(shareHolder, shareOf[shareHolder][_optionId]);
        }
        for (uint i = 0; i < poolOfSlice.length; i++) {
            address poolHolder = poolOfSlice[i];
            uint pool = poolOf[poolHolder];
            uint income = pool + equity * pool / totalPool;
            accounts.increaseToken(poolHolder, income);
        }
        settled = true;
    }

}