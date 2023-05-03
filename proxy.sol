// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

// 利用接口调用Proxy合约的"inc"函数，但Proxy中没有这个函数
// 利用delegatecall调用了implementation中的inc函数
interface ProxyInterface {
    // 一开始合约为V1
    function inc() external;
    // 合约升级为V2
    function dec() external;
}

contract Proxy {
    address public implementation;
    uint public x;

    function setImplementation(address _imp) external {
        implementation = _imp;
    }

    // 当proxy的客户端以某种方式来把proxy当作具有完整业务功能的合约来调用它的各种功能函数时，
    // 这些调用都会被转发给implementation
    fallback() external payable {
        (bool success, ) = implementation.delegatecall(msg.data);
        if(!success)
            revert("failed!");
    }
}

contract V1 {
    // 此处为了和Proxy数据内存布局兼容，只是摆设
    address public implementation;
    uint public x;

    function inc() external {
        x += 1;
    }
}

contract V2 {
    // 此处为了和Proxy数据内存布局兼容，只是摆设
    address public implementation;
    uint public x;

    function inc() external {
        x += 1;
    }

    function dec() external {
        x -= 1;
    }
}