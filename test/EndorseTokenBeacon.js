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

describe("EndorseTokenBeacon", function() {

  let TokenContract;
  let deployed_address;
  let TokenBeacon;
  let deployedTokenBeacon;

  let redeployedContract;

  let owner;
  let addr1;
  let addr2;
  let addrs;

  beforeEach(async function() {

    await hre.network.provider.send("hardhat_reset")
    TokenContract = await ethers.getContractFactory("EndorseERC721");
    TokenBeacon = await ethers.getContractFactory("EndorseTokenBeacon");
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    endorseERC721 = await TokenContract.deploy();
    await endorseERC721.initialize("EndorseERC721","ET", owner.address);
    deployed_address = endorseERC721.address;
    
    deployedTokenBeacon = await TokenBeacon.deploy(deployed_address, owner.address);
    //deploy ShareableERC721 again
    redeployedContract = await TokenContract.deploy()
  }); 

  describe("Deployment", function() {
 
    it("Should be set the right symbol", async function() {
      expect(await endorseERC721.symbol()).to.equal("ET");
    });
    
    it("Should be set the right token name", async function() {
      expect(await endorseERC721.name()).to.equal("EndorseERC721");
    });
    
    it("Token beacon should have right implementation address", async function() {
      expect(await deployedTokenBeacon.implementation()).to.equal(deployed_address);
    });

    it("Beacon should be upgreadable", async function() {
      const upgrade = await deployedTokenBeacon.update(redeployedContract.address)
      expect(await deployedTokenBeacon.implementation()).to.equal(redeployedContract.address);
    });

    it("Beacon should not be upgreadable by others", async function() { //Todo: currently upgradeable by anyone through the parent contract
      await expect(deployedTokenBeacon.connect(addr1).update(redeployedContract.address)).to.be.reverted
    });
  });  
})