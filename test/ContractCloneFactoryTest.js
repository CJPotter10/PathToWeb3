const chai = require("chai");
const { ethers } = require("hardhat");
const { solidity, deployContract } = require("ethereum-waffle");
const { inputToConfig } = require("@ethereum-waffle/compiler");
chai.use(solidity);
const { expect } = chai;

let client;
let freelancer;
let dao;
let proxy;
let factory;
let Factory;
let provider;
let ContractWallet;
let implementationContract;
let RoyaltyAddress;

describe("Testing the deployment of Clones and using the clones", function () {
  beforeEach("Deploy Factory Contract", async function () {
    [client, freelancer, dao, RoyaltyAddress] = await ethers.getSigners();
    provider = ethers.provider;
    ContractWallet = await ethers.getContractFactory("ContractWalletETH");
    implementationContract = await ContractWallet.deploy();
    await implementationContract.deployed();
    Factory = await ethers.getContractFactory("ContractCloneFactory");
    factory = await Factory.deploy(implementationContract.address, RoyaltyAddress.address);
    await factory.deployed();
  });

  it("Should propose a contract to freelancer", async function () {
    await factory.connect(client).proposeContract(client.address, freelancer.address, false, 1000000);
    const result = await factory.getProposal(0);
    expect(result.client).to.equal(client.address);
    expect(result.freelancer).to.equal(freelancer.address);
    expect(result.oneTimePayment).to.equal(false);
    expect(result.totalPayout).to.equal(1000000);
    expect(result.Confirmations).to.equal(1);
    expect(result.deployed).to.equal(false);
  });

  describe("Test the contract proposal to deployment flow", function () {
    beforeEach("Propose a contract with the client", async function () {
      await factory.connect(client).proposeContract(client.address, freelancer.address, false, 1000000);
    });

    it("Confirmations should be one as the person proposing the contract confirms it on proposal", async function () {
      const results = await factory.getProposal(0);
      expect(results.Confirmations).to.equal(1);
    });

    it("Confirm Proposal 0 with the freelancer", async function () {
      await factory.connect(freelancer).confirmProposal(0);
      let results = await factory.getProposal(0);
      expect(results.Confirmations).to.equal(2);
    });

    it("With 2 confirmations you can deploy the proxy contract", async function () {
      await factory.connect(freelancer).confirmProposal(0);
      await expect(factory.connect(freelancer).deployContract(0))
        .to.emit(factory, 'ProxyDeployed');
    });

    describe("Test using a deployed proxy contract", function () {
      beforeEach("Confirm and deploy and a contract", async function () {
        await factory.connect(freelancer).confirmProposal(0);
        await factory.connect(freelancer).deployContract(0);
      });

      it("Should return the proxy contract object that was deployed", async function () {
        const results = await factory.getProxyObject(0);
        const {0: proxyAddress, 1: clientAddress, 2: freelancerAddress } = results;
        expect(proxyAddress).to.not.be.undefined;
        expect(clientAddress).to.equal(client.address);
        expect(freelancerAddress).to.equal(freelancer.address);
      });

      it("Testing getBalance function on proxy contract", async function () {
        expect(await factory.connect(client).callGetBalance(0)).to.equal(0);
      });

      it("Deposit money into contract to fund project", async function () {
        const results = await factory.connect(client).depositIntoInstance(0, { value: 1000000 });
        expect(results).to.not.be.undefined;
        expect(await factory.connect(client).callGetBalance(0)).to.equal(1000000);
      });

      it("Propose a transaction with the freelancer for the total payout", async function () {
        await factory.connect(client).depositIntoInstance(0, { value: 1000000 });
        expect(await factory.connect(freelancer).callProposeTransaction(0, freelancer.address, 1000000))
          .to.emit(factory, 'TransactionProposed')
          .withArgs(0,0,freelancer.address);
      });

      it("Propose a transaction and confirm it with the other party", async function () {
        await factory.connect(client).depositIntoInstance(0, { value: 1000000 });
        await factory.connect(freelancer).callProposeTransaction(0, freelancer.address, 1000000);
        expect(await factory.connect(client).callConfirmTransaction(0, 0))
          .to.emit(factory, 'TransactionConfirmed')
          .withArgs(0,0, client.address);
      });

      it("Should execute transaction once confirmed and the balance of the contract should be zero", async function () {
        await factory.connect(client).depositIntoInstance(0, { value: 1000000 });
        await factory.connect(freelancer).callProposeTransaction(0, freelancer.address, 1000000);
        await factory.connect(client).callConfirmTransaction(0, 0);
        expect(await factory.connect(freelancer).callExecuteTransaction(0,0))
          .to.emit(factory, 'TransactionExecuted')
          .withArgs(0,0,0);
      });
    })
  });
})
