// 允许任何用户向这个合约里捐款
// 允许合约部署者把用户捐的钱提走
// 可以看到每个用户捐钱的数量
// 设定一个最小金额，小于这个金额(100 USD)，则捐款不成功

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "./EthToUsd.sol";

error NotOwner();

/**
* 捐款合约
* 减少gas消耗的优化措施：1. 常量加constant关键字；2. 只需在constructor中改变一次的变量加immutable关键字；3. 定义自己的error，减少使用require语句。
*/
contract FundMe {

    using EthToUsd for uint;

    // 不加immutable，部署时消耗的gas为848053
    // 加immutable，部署时消耗的gas为821784
    // 不加immutable，查看i_owner消耗的gas为2555
    // 加immutable，查看i_owner消耗的gas为422 
    address immutable public i_owner;

    // 不加constant，部署时消耗的gas为938265
    // 加constant，部署时消耗的gas为912516
    uint constant minimumUSD = 100;

    // address动态数组记录每个捐献者地址
    address[] public funders;

    // 记录每个地址的捐献金额
    mapping(address => uint) public addressToDonationAmount;

    modifier onlyOwner() {
        // 使用require时，"Not contract deployer!"字符串会被写到区块链上
        // require(msg.sender == i_owner, "Not contract deployer!");
        // 使用require时，部署合约消耗的gas为821770
        // 不使用require，使用自定义错误时，部署合约消耗的gas为792856
        if(msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    constructor() {
        i_owner = msg.sender;
    } 

    // payable表示可以往里存款
    function fund() public payable {
        // 捐款金额必须多于1ether
        // require(msg.value > 1 ether, "Must be greater than 1e18 wei!");
        // The following needs contract to be deployed on Goerli Testnet
        // require(etherToUsd(msg.value) > minimumUSD, "Must be greater than 100 USD!");

        // Using library
        require(msg.value.etherToUsd() > minimumUSD, "Must be greater than 100 USD!");

        funders.push(msg.sender);
        addressToDonationAmount[msg.sender] = msg.value;
    }

    // 设置新的owner
    // function setNewOwner(address _newOwner) public onlyOwner {
    //     i_owner = _newOwner;
    // }

    function withdraw() public onlyOwner {
        
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

}