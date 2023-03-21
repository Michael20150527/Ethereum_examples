// 允许任何用户向这个合约里捐款
// 允许合约部署者把用户捐的钱提走
// 可以看到每个用户捐钱的数量
// 设定一个最小金额，小于这个金额(100 USD)，则捐款不成功

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
* 捐款合约
*/
contract FundMe {

    AggregatorV3Interface internal priceFeed;

    address public owner;

    uint minimumUSD = 100;

    // address动态数组记录每个捐献者地址
    address[] public funders;

    // 记录每个地址的捐献金额
    mapping(address => uint) public addressToDonationAmount;

    constructor() {
        // ETH / USD on Goerli Testnet
        priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        owner = msg.sender;
    } 

    // payable表示可以往里存款
    function fund() public payable {
        // 捐款金额必须多于1ether
        // require(msg.value > 1 ether, "Must be greater than 1e18 wei!");
        // The following needs contract to be deployed on Goerli Testnet
        // require(etherToUsd(msg.value) > minimumUSD, "Must be greater than 100 USD!");

        funders.push(msg.sender);
        addressToDonationAmount[msg.sender] = msg.value;
    }

    function withdraw() public {
        require(msg.sender == owner, "Not contract deployer!");
        // 将合约余额全部转给合约的部署者
        // transfer, send和call都能实现转账，transfer和send都需要限制2300 gas，call可以不限制gas
        // payable(msg.sender).transfer(address(this).balance);

        // 使用send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Transaction failed");

        // 使用call
        (bool sent,) = payable(msg.sender).call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");

        // 通过一个for循环将每个地址匹配的捐款数量变为0
        for(uint i; i < funders.length; i++) {
            addressToDonationAmount[funders[i]] = 0;
        }

        // 取款后清空捐款人信息
        // 方法：重新创建一个含有0个元素的数组
        funders = new address[](0);
    }

    /**
     * Returns the latest ETH price.
     */
    function getLatestETHPrice() public view returns (uint) {
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
    function etherToUsd(uint etherAmount) public view returns(uint) {
        uint etherPrice = getLatestETHPrice();
        uint etherInUsd = (etherPrice * etherAmount) / 1e26; // etherPrice: 129900000000/1e8, etherAmount: 1/1e18
        return etherInUsd;
    }

}