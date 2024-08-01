// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Handler} from "./Handler.t.sol";
import {TokenSale} from "../../src/TokenSale.sol";

contract Invariant is StdInvariant, Test {
    TokenSale public tokenSale;
    Handler public handler;
    function setUp() public {
        tokenSale = (new TokenSale){value: 1 ether}();
        handler = new Handler(tokenSale);
        vm.deal(address(handler), 4 ether);

        targetContract(address(handler));
    }

    function invariant_statefulFuzz_isCompleteAlwaysFalse() public {
        assert(!tokenSale.isComplete());
    }
}
