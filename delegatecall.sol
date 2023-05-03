// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract B {
    uint public num;
    address public sender;
    uint public value;
    bytes public cdata;

    function setVars(uint _num) public payable {
        num = _num;
        sender = msg.sender;
        value = msg.value;
        cdata = msg.data;
    }
}

contract A {
    uint public num;
    address public sender;
    uint public value;
    bytes public cdata;

    function setVars(address _contract, uint _num) public payable {
        (bool success, bytes memory data) = _contract.delegatecall(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
    }

    function setVarsByCall(address _contract, uint _num) public payable {
        // call函数操作的是合约
        (bool success, bytes memory data) = _contract.call(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
    }
}