// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 price,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
    function decimals() external view returns (uint8);
}

contract ChainlinkPriceFeed {
    mapping(string => AggregatorV3Interface) public priceFeeds;
    mapping(string => uint256) public lastUpdated;
    uint256 public constant STALE_THRESHOLD = 3600; // 1 hour
    
    event PriceFeedAdded(string indexed symbol, address indexed feed);
    event PriceUpdated(string indexed symbol, int256 price, uint256 timestamp);
    
    function addPriceFeed(string memory symbol, address feedAddress) external {
        require(feedAddress != address(0), "Invalid feed address");
        priceFeeds[symbol] = AggregatorV3Interface(feedAddress);
        emit PriceFeedAdded(symbol, feedAddress);
    }
    
    function getLatestPrice(string memory symbol) external view returns (int256, uint256) {
        AggregatorV3Interface feed = priceFeeds[symbol];
        require(address(feed) != address(0), "Price feed not found");
        
        (, int256 price, , uint256 updatedAt, ) = feed.latestRoundData();
        require(price > 0, "Invalid price");
        require(block.timestamp - updatedAt <= STALE_THRESHOLD, "Stale price data");
        
        return (price, updatedAt);
    }
    
    function getPriceWithDecimals(string memory symbol) external view returns (int256, uint8, uint256) {
        AggregatorV3Interface feed = priceFeeds[symbol];
        require(address(feed) != address(0), "Price feed not found");
        
        (, int256 price, , uint256 updatedAt, ) = feed.latestRoundData();
        uint8 decimals = feed.decimals();
        
        require(price > 0, "Invalid price");
        require(block.timestamp - updatedAt <= STALE_THRESHOLD, "Stale price data");
        
        return (price, decimals, updatedAt);
    }
    
    function convertToUSD(string memory symbol, uint256 amount) external view returns (uint256) {
        (int256 price, uint8 decimals, ) = this.getPriceWithDecimals(symbol);
        return (amount * uint256(price)) / (10 ** decimals);
    }
    
    function isStale(string memory symbol) external view returns (bool) {
        AggregatorV3Interface feed = priceFeeds[symbol];
        if (address(feed) == address(0)) return true;
        
        (, , , uint256 updatedAt, ) = feed.latestRoundData();
        return block.timestamp - updatedAt > STALE_THRESHOLD;
    }
    
    function getFeedAddress(string memory symbol) external view returns (address) {
        return address(priceFeeds[symbol]);
    }
}
