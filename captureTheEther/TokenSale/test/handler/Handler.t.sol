// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Test} from "forge-std/Test.sol";
import {TokenSale} from "../../src/TokenSale.sol";

contract Handler is Test {
    TokenSale immutable i_tokenSale;

    constructor(TokenSale _tokenSale) payable {
        i_tokenSale = _tokenSale;
    }

    function buy(uint256 numTokens) public payable {
        if (address(this).balance > numTokens * 1 ether) {
            i_tokenSale.buy{value: numTokens * 1 ether}(numTokens);
        }
    }

    function sell(uint256 numTokens) public {
        bound(numTokens, 0, i_tokenSale.balanceOf(address(this)));
        i_tokenSale.sell(numTokens);
    }

    function buyAndSell(uint256 numTokens) public {
        bound(numTokens, 0, type(uint256).max);
        uint256 overFlowNumberOfTokensDividedPerEthPrice = numTokens /
            1 ether +
            1;
        uint256 expectedOverflow = overFlowNumberOfTokensDividedPerEthPrice *
            1 ether;
        i_tokenSale.buy{value: expectedOverflow}(
            overFlowNumberOfTokensDividedPerEthPrice
        );

        i_tokenSale.sell(1);
    }
}
