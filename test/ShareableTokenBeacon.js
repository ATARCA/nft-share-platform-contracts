const { inputToConfig } = require("@ethereum-waffle/compiler");
const { Description } = require("@ethersproject/properties");
const { expect } = require("chai");
const { keccak256, toUtf8Bytes, formatBytes32String } = require("ethers/lib/utils");
const { ethers, upgrades } = require("hardhat");
const hre = require("hardhat");

//Todo: check that events are fired correctly

//Todo: abstract to a helper library
const logEvents = async function(calledMethod) {
  const receipt = await calledMethod.wait()
  for (const event of receipt.events) {
    console.log(`Event ${event.event} with args ${event.args}`);
  }
}

describe("ShareableTokenBeacon", function() {

  let TokenContract;
  let shareableERC721;
  let deployed_address;
  let TokenBeacon;
  let deployedTokenBeacon;

  let redeployedShareableERC721;

  let owner;
  let addr1;
  let addr2;
  let addrs;
  let tokenURIBase

  beforeEach(async function() {

    await hre.network.provider.send("hardhat_reset")
    TokenContract = await ethers.getContractFactory("ShareableERC721");
    TokenBeacon = await ethers.getContractFactory("ShareableTokenBeacon");
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    shareableERC721 = await TokenContract.deploy();
    await shareableERC721.initialize("ShareableToken","ST", owner.address);
    //await shareableERC721.deployed();
    deployed_address = shareableERC721.address;
    
    deployedTokenBeacon = await TokenBeacon.deploy(deployed_address, owner.address);
    //console.log('Owner of beacon', await deployedTokenBeacon.owner())

    //deploy ShareableERC721 again
    
    redeployedShareableERC721 = await TokenContract.deploy()

    //Deploy proxy

    //tokenURIBase = 'domain/metadata/';
    //shareableERC721.setBaseURI(tokenURIBase);
  }); 

  describe("Deployment", function() {
 
    it("Should be set the right symbol", async function() {
      expect(await shareableERC721.symbol()).to.equal("ST");
    });

    it("Should be set the right token name", async function() {
      expect(await shareableERC721.name()).to.equal("ShareableToken");
    });

    it("Token beacon should have right implementation address", async function() {
      expect(await deployedTokenBeacon.implementation()).to.equal(deployed_address);
    });

    it("Beacon should be upgreadable", async function() {
      const upgrade = await deployedTokenBeacon.update(redeployedShareableERC721.address)
      expect(await deployedTokenBeacon.implementation()).to.equal(redeployedShareableERC721.address);
    });

    it("Beacon should not be upgreadable by others", async function() { //Todo: currently upgradeable by anyone through the parent contract
      await expect(deployedTokenBeacon.connect(addr1).update(redeployedShareableERC721.address)).to.be.reverted
    });

    /*it("Upgraded contract should have the same state post-upgrade", async function() {
      //Todo: mint couple of tokens
      //Todo: 
      expect(await shareableERC721.getIndex()).to.equal(0)
      await shareableERC721.mint(addr1.address)
      await shareableERC721.mint(addr2.address)
      expect(await shareableERC721.getIndex()).to.equal(2)
      const upgrade = await deployedTokenBeacon.updateShareableToken(redeployedShareableERC721.address)
      expect(await redeployedShareableERC721.getIndex()).to.equal(2)
    });*/
    
    //Check who is owner of the Beacon contract (should be the smart contract that deployed it)
    
    //Check who is owner of the sToken contract 

    //Upgraded address should point to right address
    //Upgraded contract should have right contract state

    //Only deployer should be able to upgrade beacon

  });

  
})