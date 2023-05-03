// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract ReceiveEther {
    event Fallback(bytes cdata, uint value, uint gas);
    event Foo(bytes cdata, uint value, uint gas);

    fallback() external payable {
        emit Fallback(msg.data, msg.value, gasleft());
    }

    receive() external payable {
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function foo() public payable{
        emit Foo(msg.data, msg.value, gasleft());
    }
}

contract SendEther {

    function sendViaCall(address payable _to) public payable {
        (bool sent,) = _to.call{value: msg.value}("");
        require(sent, "Failed to send ether");
    }

    function sendViaFoo(address payable _to) public payable {
        ReceiveEther re = ReceiveEther(_to);
        // msg.value是sendViaFoo的调用者发送给SendEther合约的钱
        // 这个钱又通过以下的语句转给了ReceiveEther合约
        re.foo{value: msg.value}();
    }
}