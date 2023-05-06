// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

// 利用接口调用Proxy合约的"inc"函数，但Proxy中没有这个函数
// 利用delegatecall调用了implementation中的inc函数
interface ProxyInterface {
    // 一开始合约为V1
    function inc() external;
    // 合约升级为V2
    function x() external view returns(uint);
}

contract Proxy {
    bytes32 private constant implementationPosition = keccak256("org.zeppelinos.proxy.implementation");

    function upgradeTo(address newImplementation) public {
        // address currentImplementation = implementation();
        setImplementation(newImplementation);
    }

    function implementation() public view returns(address impl) {
        bytes32 position = implementationPosition;
        assembly {
            impl := sload(position)
        }
    }

    function setImplementation(address newImplementation) internal {
        bytes32 position = implementationPosition;
        assembly {
            sstore(position, newImplementation)
        }
    }

    function _delegate(address _impl) internal virtual {
        assembly {
            // calldatacopy(t, f, s)
            // copy s bytes from calldata at position f to mem at position t
            calldatacopy(0, 0, calldatasize())

            // delegatecall(g, a, in, insize, out, outsize)
            // - call contract at address a
            // - with input mem[in...(in+insize))
            // - providing g gas
            // - and output area mem[out...(out+outsize))
            // - returning 0 on error and 1 on success
            let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)

            // returndatacopy(t, f, s)
            // copy s bytes from returndata at position f to mem at position t
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                // revert(p, s)
                // end execution, revert state changes, return data mem[p..(p+s))
                revert(0, returndatasize())
            }
            default {
                // return(p, s)
                // end execution, return data mem[p..(p+s))
                return(0, returndatasize())
            }
        }
    }

    // 当proxy的客户端以某种方式来把proxy当作具有完整业务功能的合约来调用它的各种功能函数时，
    // 这些调用都会被转发给implementation
    fallback() external payable {
        _delegate(implementation());
    }
}

contract V1 {
    uint public x;

    function inc() external {
        x += 1;
    }
}

contract V2 {
    uint public x;

    function inc() external {
        x += 1;
    }

    function dec() external {
        x -= 1;
    }
}

// 模拟客户端调用
contract Client {
    address proxy;

    constructor(address _proxy) public {
        proxy = _proxy;
    }

    function inc() public {
        ProxyInterface pi = ProxyInterface(proxy);
        pi.inc();
    }

}