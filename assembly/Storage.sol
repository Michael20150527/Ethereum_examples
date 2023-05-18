// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Storage {

    uint256 number;

    function store(uint256 num) public {
        assembly {
            // storage[number.slot] = num
            sstore(number.slot, num)
        }
    }

    function retrieve() public view returns (uint256){
        assembly {
            // rst = storage[number.slot], 从storage中取出rst载入栈顶
            let rst := sload(number.slot)
            // 存入这段内存memory[0:0+32] = rst
            mstore(0, rst)
            // return memory[0:0+32]，返回内存中0到0+32这段内存的值
            return(0, 32)
        }
    }

    function readData() public view returns (uint256){
        assembly {
            // rst = storage[number.slot], 从storage中取出rst载入栈顶
            let rst := sload(number.slot)
            // 得到free memory pointer
            let free_pointer := mload(0x40)
            // 存入这段内存memory[0:0+32] = rst
            mstore(free_pointer, rst)
            // return memory[0:0+32]，返回内存中0到0+32这段内存的值
            return(free_pointer, 32)
        }
    }
}