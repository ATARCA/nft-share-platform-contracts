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

describe("LikeTokenBeacon", function() {

  let TokenContract;
  let likeERC721;
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
    TokenContract = await ethers.getContractFactory("LikeERC721");
    TokenBeacon = await ethers.getContractFactory("TokenBeacon");
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    likeERC721 = await TokenContract.deploy();
    await likeERC721.initialize("LikeERC721","LT", owner.address);
    deployed_address = likeERC721.address;
    
    deployedTokenBeacon = await TokenBeacon.deploy(deployed_address, owner.address);    
    redeployedContract = await TokenContract.deploy()
  }); 

  describe("LikeERC721 and TokenBeacon", function() {
 
    it("Should be set the right symbol", async function() {
      expect(await likeERC721.symbol()).to.equal("LT");
    });
    
    it("Should be set the right token name", async function() {
      expect(await likeERC721.name()).to.equal("LikeERC721");
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