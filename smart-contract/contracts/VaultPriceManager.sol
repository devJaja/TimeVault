// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ChainlinkPriceFeed.sol";

contract VaultPriceManager {
    ChainlinkPriceFeed public priceFeed;
    
    constructor(address _priceFeed) {
        priceFeed = ChainlinkPriceFeed(_priceFeed);
    }
    
    function getVaultValueInUSD(string memory token, uint256 amount) external view returns (uint256) {
        return priceFeed.convertToUSD(token, amount);
    }
}
