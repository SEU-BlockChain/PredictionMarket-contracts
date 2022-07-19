// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


library IssueLib {
    struct T {
        uint length;
        mapping(address => bool) valid;
        mapping(address => info) data;
    }

    struct info {
        uint[3] time_pool_volume;
        uint state;
        uint topic;
        address market;
        mapping(address => bool) followed;
        address[3] by_time_pool_volume_prev;
        address[3] by_time_pool_volume_next;
    }

    struct template {
        address issue;
        uint[3] time_pool_volume;
        uint state;
        uint topic;
        address market;
    }

    modifier valid(T storage _self, address _issue){
        require(_self.valid[_issue], "invalid issue");
        _;
    }

    function _findIndex(T storage _self, uint _type, uint _value)
    internal view returns (address) {
        address candidate = address(1);
        address next_candidate;
        while (true) {
            next_candidate = _self.data[candidate].by_time_pool_volume_next[_type];
            if (_verifyIndex(_self, _type, candidate, _value, next_candidate)) return candidate;
            candidate = next_candidate;
            if (candidate == address(1)) break;
        }
        return address(0);
    }

    function _verifyIndex(T storage _self, uint _type, address _prev, uint256 _value, address _next)
    internal view returns (bool){
        return (_prev == address(1) || _value >= _self.data[_prev].time_pool_volume[_type]) && (_next == address(1) || _value > _self.data[_next].time_pool_volume[_type]);
    }


    function _insert(T storage _self, address _issue, uint _type, uint _value)
    internal {
        address index = _findIndex(_self, _type, _value);
        require(index != address(0), "unable to find index");
        _self.data[_issue].by_time_pool_volume_next[_type] = _self.data[index].by_time_pool_volume_next[_type];
        _self.data[_issue].by_time_pool_volume_prev[_type] = index;
        _self.data[_self.data[index].by_time_pool_volume_next[_type]].by_time_pool_volume_prev[_type] = _issue;
        _self.data[index].by_time_pool_volume_next[_type] = _issue;
    }

    function _update(T storage _self, address _issue, uint _type, uint _value)
    internal {
        address prev = _self.data[_issue].by_time_pool_volume_prev[_type];
        address next = _self.data[_issue].by_time_pool_volume_next[_type];
        if (!_verifyIndex(_self, _type, prev, _value, next)) {
            _self.data[prev].by_time_pool_volume_next[_type] = next;
            _self.data[next].by_time_pool_volume_prev[_type] = prev;
            _insert(_self, _issue, _type, _value);
        }
        _self.data[_issue].time_pool_volume[_type] = _value;
    }

    function init(T storage _self)
    external {
        _self.valid[address(1)] = true;
        info storage head = _self.data[address(1)];
        head.by_time_pool_volume_prev = head.by_time_pool_volume_next = [address(1), address(1), address(1)];
    }

    function create(T storage _self, address _issue, uint[3] calldata _time_pool_volume, uint _state, uint _topic, address _market)
    external valid(_self, _issue) {
        info storage issue = _self.data[_issue];
        issue.time_pool_volume = _time_pool_volume;
        issue.state = _state;
        issue.topic = _topic;
        issue.market = _market;
        for (uint i = 0; i < 3; i++) {
            _insert(_self, _issue, i, _time_pool_volume[i]);
        }
        _self.length++;
    }

    function changePool(T storage _self, address _issue, uint _pool)
    external valid(_self, _issue) {
        _update(_self, _issue, 1, _pool);
    }

    function changeVolume(T storage _self, address _issue, uint _volume)
    external valid(_self, _issue) {
        _update(_self, _issue, 2, _volume);
    }

    function changeState(T storage _self, address _issue, uint _state)
    external valid(_self, _issue) {
        _self.data[_issue].state = _state;
    }

    function follow(T storage _self, address _issue, address _follower, bool _follow)
    external valid(_self, _issue) {
        _self.data[_issue].followed[_follower] = _follow;
    }

    function range(T storage _self, address _cursor, uint _type, bool _reverse, uint _state, uint _topic, address _market, address _follower)
    external view valid(_self, _cursor) returns (template[10] memory){
        address cursor = _cursor;
        uint current = 0;
        template[10] memory res;
        while (current < 10) {
            cursor = _reverse ? _self.data[cursor].by_time_pool_volume_prev[_type] : _self.data[cursor].by_time_pool_volume_next[_type];
            if (cursor == address(1)) break;
            info storage issue = _self.data[cursor];
            if (_state != 0 && _state != issue.state) continue;
            if (_topic != 0 && _topic != issue.topic) continue;
            if (_market != address(0) && issue.market != _market) continue;
            if (_follower != address(0) && !issue.followed[_follower]) continue;
            res[current] = template(cursor, issue.time_pool_volume, issue.state, issue.topic, issue.market);
            current++;
        }
        return res;
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