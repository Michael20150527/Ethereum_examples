pragma solidity >0.4.0;

contract C {
    mapping(address => uint) public balances;

    constructor() public {
        // C合约实例的地址上存300个以太
        balances[address(this)] = 300;
    }

    function update(uint amount) public {
        // 对应C合约来说，这里的msg.sender就是D合约的地址，因为是D调用了C
        balances[msg.sender] = amount;
    }
}

contract D {
    function fun() public returns(uint) {
        C c = new C();
        c.update(30);
        // c合约实例上的以太为300个
        // return c.balances(address(c));
        // D合约地址上的以太为（"0": "uint256: 30"）
        // return c.balances(address(this));
        // 这里的msg.sender地址上的以太为（"0": "uint256: 0"）
        // 因为这里的msg.sender指的是调用合约D的Account，而合约C中的msg.sender指的是调用它的D合约地址
        return c.balances(address(msg.sender));
    }
}