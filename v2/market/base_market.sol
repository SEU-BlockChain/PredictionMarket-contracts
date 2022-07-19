// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./prediction_market.sol";
import "../prediction/binary_prediction_v1.sol";
import "../typing/library.sol";

contract BaseMarket {
    PrivateAccountManager account;
    PredictionMarket public market;

    modifier marketOpen(address _market){
        require(market.marketOpen(_market), "invalid market");
        _;
    }
}