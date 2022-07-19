// SPDX-License-Identifier: GPL-3.0

import "../market/prediction_market.sol";
import "../typing/library.sol";
import "../typing/interface.sol";
import "../typing/struct.sol";
import "./base_prediction.sol";
import "../lib/modifier.sol";

pragma solidity >=0.7.0 <0.9.0;

contract BinaryPredictionV1 is BasePrediction,BaseModifier {
    PredictionMarket public market;
    
    string topic;

    struct BinaryOption {
        uint share;
        string desc;
    }

    BinaryOption[] public options;

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
    event ShareChangeEvent(uint timestamp, uint optionId, uint share);

    constructor(address _owner,PrivateAccountManager _account, PredictionMarket _market, BasePredictionInfo memory _info){
        owner=_owner;
        account = _account;
        market = _market;
        info = _info;
        
        init_amount=_info.init_amount;
        option_num=_info.options.length;
        totalShare = init_amount*option_num;
        
        for (uint i = 0; i < option_num; i++) {
            options.push(BinaryOption(init_amount, _info.options[i]));
        }

        account.decreaseToken(_owner, init_amount);

        poolOfMapping[_owner] = true;
        poolOfSlice.push(_owner);
        poolOf[_owner]+=init_amount*2;
        totalPool += init_amount*2;

        market.initIssue(address(this));
        market.createIssue(address(this),[block.timestamp,totalPool,totalPool+totalShare],0,_info.topic,address(_market));
    }

     modifier shareEnough(uint _optionId, uint _share){
        require(shareOf[msg.sender][_optionId] >= _share, "insufficient share");
        _;
    }

    modifier poolEnough(uint _amount){
        require(poolOf[msg.sender] >= _amount, "insufficient pool");
        _;
    }

    function utility(uint x,uint V,uint p_e2)
    internal pure returns(uint U){
        U=x+100*V*V/((100-p_e2)*x+100*V)-V;
    }

    function _allocate(uint _optionId, uint _share) 
    internal view returns (uint _amount,uint _equity){
        uint sender_share=shareOf[msg.sender][_optionId];
        uint p_e2=100*(options[_optionId].share-sender_share)/(totalShare-sender_share);
        uint V=totalPool*option_num+totalShare/option_num;
        uint before_utility=utility(sender_share,V,p_e2);
        uint after_utility=utility(sender_share+_share,V,p_e2);
        _amount=after_utility-before_utility;
        _equity=_amount/100+1;
        _amount+=_equity;
    }

    function _withdraw(uint _optionId, uint _share) 
    internal view returns (uint _amount,uint _equity){
        uint sender_share=shareOf[msg.sender][_optionId];
        uint p_e2=100*(options[_optionId].share-sender_share)/(totalShare-sender_share);
        uint V=totalPool*option_num+totalShare/option_num;
        uint before_utility=utility(sender_share,V,p_e2);
        uint after_utility=utility(sender_share-_share,V,p_e2);
        _amount=before_utility-after_utility;
        _equity=_amount/100+1;
        _amount-=_equity;
    }

    function longOptionEstimate(uint _optionId, uint _share) 
    external view activated positive(_share) returns(uint _amount,uint _equity){
        (_amount,_equity)=_allocate(_optionId,_share);
        require(_amount<=account.balanceOf(msg.sender),"no enough token");
    }

    function shortOptionEstimate(uint _optionId, uint _share) 
    external view activated positive(_share)  shareEnough(_optionId,_share) returns(uint _amount,uint _equity){
        (_amount,_equity)=_withdraw(_optionId,_share);
        require(_amount>_equity,"share to small");
    }

    function longOption(uint _optionId, uint _share) 
    external activated{
        uint _amount;
        uint _equity;
        (_amount,_equity)=_allocate(_optionId,_share);
        require(_amount<=account.balanceOf(msg.sender),"no enough token");
        
        account.decreaseToken(msg.sender, _amount);
        
        shareOf[msg.sender][_optionId] += _share;
        totalShare += _share;
        options[_optionId].share += _share;
        equity += _equity;

        emit LongOptionEvent(msg.sender, _optionId, _amount, _share);
        emit ShareChangeEvent(block.timestamp, _optionId, options[_optionId].share);

        if (!shareOfMapping[msg.sender]) {
            shareOfMapping[msg.sender] = true;
            shareOfSlice.push(msg.sender);
        }
    }

    function shortOption(uint _optionId, uint _share) 
    external activated shareEnough(_optionId, _share) {
        uint _amount;
        uint _equity;
        (_amount,_equity)=_withdraw(_optionId,_share);

        account.increaseToken(msg.sender, _amount);

        shareOf[msg.sender][_optionId] -= _share;
        totalShare -= _share;
        options[_optionId].share -= _share;
        equity += _equity;

        emit ShortOptionEvent(msg.sender, _optionId, _amount, _share);
        emit ShareChangeEvent(block.timestamp, _optionId, options[_optionId].share);
    }

    function longPool(uint _amount) 
    external activated tokenEnough(account, msg.sender,_amount){
        account.decreaseToken(msg.sender,_amount);
        totalPool += _amount;
        poolOf[msg.sender] += _amount;

        emit LongPoolEvent(msg.sender, _amount);
        
        if (!poolOfMapping[msg.sender]) {
            poolOfMapping[msg.sender] = true;
            poolOfSlice.push(msg.sender);
        }
    }

    function _settle(uint _optionId) 
    external ownerOnly hasClosed notSettled{
        for (uint i = 0; i < shareOfSlice.length; i++) {
            address shareHolder = shareOfSlice[i];
            account.increaseToken(shareHolder, shareOf[shareHolder][_optionId]);
        }
        for (uint i = 0; i < poolOfSlice.length; i++) {
            address poolHolder = poolOfSlice[i];
            uint pool = poolOf[poolHolder];
            uint income = pool + equity * pool / totalPool;
            if(poolHolder==owner){
                income-=info.init_amount;
            }
            account.increaseToken(poolHolder, income);
        }
        settled = true;
    }
}
