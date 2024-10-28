// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "ds-test/test.sol";
import "forge-std/Vm.sol";

import "src/core/Ethernaut.sol";
import "src/levels/23-PuzzleWallet/PuzzleWallet.sol";

contract DexTwoTest is DSTest {
    Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
    Ethernaut ethernaut;
    address hacker = vm.addr(1); // generate random-looking address with given private key

    function setUp() public {
        ethernaut = new Ethernaut();

        // set hacker's balance to 1 Ether, use it when you need!
        // vm.deal(hacker, 1 ether);
    }

    function testPuzzleWalletHack() public {
        /////////////////
        // LEVEL SETUP //
        /////////////////
        PuzzleWallet puzzleWallet = new PuzzleWallet();
        ethernaut.registerLevel(puzzleWallet);
        vm.startPrank(hacker);
        address levelAddress = ethernaut.createLevelInstance(puzzleWallet);
        DexTwo ethernautDexTwo = DexTwo(payable(levelAddress));

        //////////////////
        // LEVEL ATTACK //
        //////////////////
        // implement your solution here

        //////////////////////
        // LEVEL SUBMISSION //
        //////////////////////
        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(
            payable(levelAddress)
        );
        vm.stopPrank();
        assert(levelSuccessfullyPassed);
    }
}
