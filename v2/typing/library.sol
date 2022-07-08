// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


library IssueLib {
    struct T {
        uint length;
        mapping(address => bool) valid;
        mapping(address => info) data;
        mapping(address => address) by_time_next;
        mapping(address => address) by_pool_next;
        mapping(address => address) by_volume_next;
    }

    struct info {
        uint o_time; //type 0
        uint o_pool; //type 1
        uint o_volume; //type 2
        uint f_state;
        uint f_topic;
        address f_market;
        mapping(address => bool) f_followed;
    }

    modifier valid(T storage _self, address _issue){
        require(_self.valid[_issue], "invalid issue");
        _;
    }

    function _verifyIndex(T storage _self, uint _type, address _prev, uint256 _new_value, address _next)
    internal view returns (bool){
        return (_prev == address(1) || _getValue(_self, _type, _prev) >= _new_value) && (_next == address(1) || _new_value > _getValue(_self, _type, _next));
    }

    function _isPrev(mapping(address => address) storage _chain, address _current, address _prev)
    internal view returns (bool) {
        return _chain[_prev] == _current;
    }

    function _findIndex(T storage _self, uint _type, mapping(address => address) storage _chain, uint _value)
    internal view returns (address) {
        address candidate = address(1);
        while (true) {
            if (_verifyIndex(_self, _type, candidate, _value, _chain[candidate]))
                return candidate;
            candidate = _chain[candidate];

            if (candidate == address(1)) {
                break;
            }
        }

        return address(0);
    }

    function _findPrev(mapping(address => address) storage _chain, address _issue)
    internal view returns (address){
        address current = address(1);
        while (_chain[current] != address(1)) {
            if (_isPrev(_chain, _issue, current)) {
                return current;
            }
            current = _chain[current];
        }
        return address(0);
    }

    function _getValue(T storage _self, uint _type, address _issue)
    internal view returns (uint){
        require(2 >= _type && _type >= 0, "invalid type");
        if (_type == 0) {
            return _self.data[_issue].o_time;
        } else if (_type == 1) {
            return _self.data[_issue].o_pool;
        } else {
            return _self.data[_issue].o_volume;
        }
    }

    function _getChain(T storage _self, uint _type)
    internal view returns (mapping(address => address) storage){
        require(2 >= _type && _type >= 0, "invalid type");
        if (_type == 0) {
            return _self.by_time_next;
        } else if (_type == 1) {
            return _self.by_pool_next;
        } else {
            return _self.by_volume_next;
        }
    }


    function _insert(T storage _self, uint _type, mapping(address => address) storage _chain, address _issue, uint _value)
    internal {
        require(_chain[_issue] == address(0), "issue exisits");
        address index = _findIndex(_self, _type, _chain, _value);
        _chain[_issue] = _chain[index];
        _chain[index] = _issue;
    }

    function init(T storage _self)
    external {
        _self.by_time_next[address(1)] = address(1);
        _self.by_pool_next[address(1)] = address(1);
        _self.by_volume_next[address(1)] = address(1);
    }


    function create(T storage _self, address _issue, uint _time, uint _pool, uint _volume, uint _state, uint _topic, address _market)
    external valid(_self, _issue) {

        mapping(address => address) storage chain = _getChain(_self, 0);
        uint value = _time;
        _insert(_self, 0, chain, _issue, value);

        chain = _getChain(_self, 1);
        value = _pool;
        _insert(_self, 1, chain, _issue, value);

        chain = _getChain(_self, 2);
        value = _volume;
        _insert(_self, 2, chain, _issue, value);

        info storage i = _self.data[_issue];
        i.o_time = _time;
        i.o_pool = _pool;
        i.o_volume = _volume;
        i.f_state = _state;
        i.f_topic = _topic;
        i.f_market = _market;
        _self.length++;
    }

    function update(T storage _self, address _issue, uint _pool, uint _volume)
    external valid(_self, _issue) {

    }

    function changeState(T storage _self, address _issue, uint _state)
    external valid(_self, _issue) {
        _self.data[_issue].f_state = _state;
    }

    function follow(T storage _self, address _issue, address _user, bool _follow)
    external valid(_self, _issue) {
        _self.data[_issue].f_followed[_user] = _follow;
    }
}

library TopicLib {
    using TopicLib for T[];

    struct T {
        string topic;
        string icon;
        bool is_active;
    }

    event CreateTopicEvent(address _creator, string _topic, uint _time);
    event FreezeTopicEvent(address _creator, string _topic, uint _time);
    event ThawTopicEvent(address _creator, string _topic, uint _time);

    function append(T[] storage _self, string calldata _topic, string calldata _icon)
    external {
        _self.push(T(_topic, _icon, true));
        emit CreateTopicEvent(msg.sender, _topic, block.timestamp);
    }

    function freeze(T[] storage _self, uint _index)
    external {
        _self[_index].is_active = false;
        emit FreezeTopicEvent(msg.sender, _self[_index].topic, block.timestamp);
    }

    function thaw(T[] storage _self, uint _index)
    external {
        _self[_index].is_active = true;
        emit ThawTopicEvent(msg.sender, _self[_index].topic, block.timestamp);
    }

    function range(T[] storage _self, uint _start)
    external view returns (T[10] memory){
        uint i = 0;
        T[10] memory res;
        uint cursor = _start;
        while (i < 10 && cursor < _self.length) {
            if (_self[cursor].is_active) {
                res[i] = _self[cursor];
                i++;
            }
            cursor++;
        }
        return res;
    }
}

library MarketLib {
    struct T {
        string name;
        uint timestamp;
        bool is_open;
        bool is_active;
    }

    event CreateMarketEvent(address _creator, address _address, string _name, uint _time);
    event OpenMarketEvent(address _creator, address _address, string _name, uint _time);
    event CloseMarketEvent(address _creator, address _address, string _name, uint _time);
    event FreezeMarketEvent(address _creator, address _address, string _name, uint _time);
    event ThawMarketEvent(address _creator, address _address, string _name, uint _time);

    function create(mapping(address => T) storage _self, address _market, string calldata _name)
    external {
        _self[_market] = T(_name, block.timestamp, true, true);
        emit CreateMarketEvent(msg.sender, _market, _name, block.timestamp);
    }

    function open(mapping(address => T) storage _self, address _market)
    external {
        _self[_market].is_open = true;
        emit OpenMarketEvent(msg.sender, _market, _self[_market].name, block.timestamp);
    }

    function close(mapping(address => T) storage _self, address _market)
    external {
        _self[_market].is_open = false;
        emit CloseMarketEvent(msg.sender, _market, _self[_market].name, block.timestamp);
    }

    function thaw(mapping(address => T) storage _self, address _market)
    external {
        _self[_market].is_active = true;
        emit ThawMarketEvent(msg.sender, _market, _self[_market].name, block.timestamp);
    }

    function freeze(mapping(address => T) storage _self, address _market)
    external {
        _self[_market].is_active = false;
        emit FreezeMarketEvent(msg.sender, _market, _self[_market].name, block.timestamp);
    }
}