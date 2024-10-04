pragma solidity ^0.5.10;

import "ds-test/test.sol";
import "forge-std/Vm.sol";

import "src/core/Ethernaut.sol";
import "src/levels/19-AlienCodex/AlienCodex.sol";
import "src/levels/19-AlienCodexFactory.sol";
import "src/levels/19-AlienCodex/Ownable-05.sol";

contract AlienCodexTest is DSTest {
    Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
    Ethernaut ethernaut;
    address hacker = vm.addr(1); // generate random-looking address with given private key

    function setUp() public {
        ethernaut = new Ethernaut();

        // set hacker's balance to 1 Ether, use it when you need!
        vm.deal(hacker, 1 ether);
    }

    function testAlienCodexHack(bytes8 key, uint8 gas) public {
        /////////////////
        // LEVEL SETUP //
        /////////////////
        //@q could this have been fuzzed in a smart way?

        AlienCodexFactory alienCodexFactory = new AlienCodexFactory();
        ethernaut.registerLevel(alienCodexFactory);
        vm.startPrank(hacker, hacker);
        address levelAddress = ethernaut.createLevelInstance{
            value: 0.001 ether
        }(alienCodexFactory);
        AlienCodex ethernautAlienCodex = AlienCodex(payable(levelAddress));
        AlienCodexAttacker alienCodexAttacker = new AlienCodexAttacker(
            ethernautAlienCodex
        );

        //////////////////
        // LEVEL ATTACK //
        //////////////////
        // implement your solution here
        ethernautAlienCodex.make_contact();
        alienCodexAttacker.attack();

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
