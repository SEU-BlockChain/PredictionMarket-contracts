// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./base_market.sol";
import "../typing/struct.sol";

contract BinaryPredictionMarketV1 is BaseMarket {
    event CreatePredictionEvent(address);
    constructor(address _account_address, address _market_address){
        account = PrivateAccountManager(_account_address);
        market = PredictionMarket(_market_address);
    }

    function createBinaryPrediction(BasePredictionInfo calldata _info)
    public marketOpen(address(this)) {
        BinaryPredictionV1 p = new BinaryPredictionV1(msg.sender, account, market, _info);
        emit CreatePredictionEvent(address(p));
    }
}