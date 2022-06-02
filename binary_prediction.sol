// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./typing.sol";

contract BinaryPrediction is BasePrediction,BaseModifier {
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
    event ShortPoolEvent(address indexed user, uint amount);
    event ShareChangeEvent(uint timestamp, uint option0, uint option1);

    constructor(address _owner,uint _init_amount, PrivateAccounts _accounts, string memory _topic, PredictionInfo memory _info, string[] memory _options){
        owner = _owner;
        init_amount=_init_amount;
        accounts = _accounts;
        topic = _topic;
        info = _info;

        option_num=_options.length;
        totalShare = init_amount*option_num;
        
        for (uint i = 0; i < option_num; i++) {
            options.push(BinaryOption(init_amount, _options[i]));
        }

        accounts.decreaseToken(_owner, init_amount);
        poolOf[_owner]+=init_amount;
        totalPool += init_amount;
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
        U=x-V+100*V*V/((100-p_e2)*x+100*V);
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
    internal view shareEnough(_optionId,_share) returns (uint _amount,uint _equity){
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
        require(_amount<=accounts.balanceOf(msg.sender),"no enough token");
    }

    function shortOptionEstimate(uint _optionId, uint _share) 
    external view activated positive(_share) returns(uint _amount,uint _equity){
        (_amount,_equity)=_withdraw(_optionId,_share);
        require(_amount>0,"share to small");
    }

    function longPool(uint _amount) 
    external activated {
        accounts.decreaseToken(msg.sender, _amount);
        totalPool += _amount;
        poolOf[msg.sender] += _amount;
        if (!poolOfMapping[msg.sender]) {
            poolOfMapping[msg.sender] = true;
            poolOfSlice.push(msg.sender);
        }
        emit LongPoolEvent(msg.sender, _amount);
    }

    function shortPool(uint _amount) 
    external activated poolEnough(_amount) {
        accounts.increaseToken(msg.sender, _amount);
        totalPool -= _amount;
        poolOf[msg.sender] -= _amount;
        emit ShortPoolEvent(msg.sender, _amount);
    }
}