// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library EthToUsd {

    /**
     * Returns the latest ETH price.
     * Library和Contract类似，只不过不能往里面存款，同时不能有状态变量，Library里面所有的function都需要是internal
     */
    function getLatestETHPrice() internal view returns (uint) {
        // ETH / USD on Goerli Testnet
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        // prettier-ignore
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return uint(price);
    }

    /**
     * etherAmount unit: wei
     */
    function etherToUsd(uint etherAmount) internal view returns(uint) {
        uint etherPrice = getLatestETHPrice();
        uint etherInUsd = (etherPrice * etherAmount) / 1e26; // etherPrice: 129900000000/1e8, etherAmount: 1/1e18
        return etherInUsd;
    }

}