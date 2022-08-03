const { inputToConfig } = require("@ethereum-waffle/compiler");
const { Description } = require("@ethersproject/properties");
const { expect } = require("chai");
const { keccak256, toUtf8Bytes, formatBytes32String } = require("ethers/lib/utils");
const { ethers, upgrades } = require("hardhat");
const hre = require("hardhat");
const _ = require("lodash");

//Todo: check that events are fired correctly

//Todo: abstract to a helper library
const logEvents = async function(calledMethod) {
  const receipt = await calledMethod.wait()
  for (const event of receipt.events) {
    console.log(`Event ${event.event} with args ${event.args}`);
  }
}

const findEvent = function(eventName, transactionReceipt) {
  return _.filter(transactionReceipt?.events, function(o) {
    return o.event == eventName
  });
}

describe("Talko Factory", function() {

  let ShareableERC721;
  let _shareableERC721;
  let LikeERC721;
  let _likeERC721;
  let EndorseableERC721;
  let _endorseableERC721;

  let ShareableERC721v2Test;

  let BeaconShareableERC721;
  let _beaconShareableERC721

  let BeaconLikeERC721;
  let _beaconLikeERC721;

  let BeaconEndorseableERC721;
  let _beaconEndorseableERC721;

  let FactoryContract;
  let _factoryContract;

  let owner;
  let addr1;
  let addr2;
  let addrs;
  let tokenURIBase

  let tokenId     = ethers.constants.Zero    
  let newTokenId  = ethers.constants.One

  let operatorRole = keccak256(ethers.utils.toUtf8Bytes("OPERATOR_ROLE"));
  let adminRole = ethers.constants.HashZero

  beforeEach(async function() {

    await hre.network.provider.send("hardhat_reset");
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    BeaconShareableERC721 = await ethers.getContractFactory("TokenBeacon");

    ShareableERC721 = await ethers.getContractFactory("ShareableERC721");
    _shareableERC721 = await ShareableERC721.deploy();
    await _shareableERC721.deployed()

    ShareableERC721v2Test = await ethers.getContractFactory("ShareableERC721v2Test");

    LikeERC721 = await ethers.getContractFactory("LikeERC721");
    _likeERC721 = await LikeERC721.deploy();
    await _likeERC721.deployed()

    EndorseableERC721 = await ethers.getContractFactory("EndorseERC721");
    _endorseableERC721 = await EndorseableERC721.deploy();
    await _endorseableERC721.deployed()

    FactoryContract = await ethers.getContractFactory("TalkoFactory");
    _factoryContract = await FactoryContract.deploy(_shareableERC721.address, _likeERC721.address, _endorseableERC721.address);
    await _factoryContract.deployed()
  }); 

  describe("Deployment", function() {
 
    it("Proxy can be deployed and has correct arguments", async function() {
      let deployedProxyAddress = await _factoryContract.createShareableERC721Proxy("ShareableToken","ST",0, owner.address);
      let receipt = await deployedProxyAddress.wait()
      let event = findEvent('ShareableERC721ProxyCreated', receipt)
      let deployAddress = event[0]?.args[0]
      expect(deployedProxyAddress).to.emit(_factoryContract, "ShareableERC721ProxyCreated").withArgs(deployAddress, owner.address, "ShareableToken", "ST")
    });

    it("Deployed proxy can be interacted with", async function() {
      //Mint a couple of tokens
      //check that tokens got minted

      let deployedProxyAddress = await _factoryContract.createShareableERC721Proxy("ShareableToken","ST",0, owner.address);
      let receipt = await deployedProxyAddress.wait()
      
      let event = findEvent('ShareableERC721ProxyCreated', receipt)
      //console.log('found event', event[0]?.args)

      let deployAddress = event[0]?.args[0]
      let proxiedST = await ShareableERC721.attach(deployAddress);

      await proxiedST.mint(addr1.address)
      await proxiedST.mint(addr2.address)
      expect(await proxiedST.ownerOf(tokenId)).to.equal(addr1.address);
    })

    it("Proxies name & symbol pair should be unique", async function() {
      let deployedProxyAddress = await _factoryContract.createShareableERC721Proxy("ShareableToken","ST",0, owner.address);
      await expect(_factoryContract.createShareableERC721Proxy("ShareableToken","ST",0, owner.address)).to.be.revertedWith("A proxy with given name and symbol already exists!")
      
      let deployedLProxyAddress = await _factoryContract.createLikeERC721Proxy("LikeERC721","LT",0, owner.address);
      await expect(_factoryContract.createLikeERC721Proxy("LikeERC721","LT",0, owner.address)).to.be.revertedWith("A proxy with given name and symbol already exists!")
      
      let deployedEProxyAddress = await _factoryContract.createEndorseERC721Proxy("EndorseERC721","ET",0, owner.address);
      await expect(_factoryContract.createEndorseERC721Proxy("EndorseERC721","ET",0, owner.address)).to.be.revertedWith("A proxy with given name and symbol already exists!")
    })

    it("Deploy proxy to different owner, deployer shouldn't have rights to proxy ", async function() {
      let deployedProxyAddress = await _factoryContract.createShareableERC721Proxy("ShareableToken","ST",0, addr1.address);
      let receipt = await deployedProxyAddress.wait()
      
      let event = findEvent('ShareableERC721ProxyCreated', receipt)

      let deployAddress = event[0]?.args[0]
      let proxiedST = await ShareableERC721.attach(deployAddress);
      await expect(proxiedST.mint(addr1.address)).to.be.reverted

      expect(await proxiedST.hasRole(adminRole, addr1.address)).to.be.true
      expect(await proxiedST.hasRole(operatorRole, addr1.address)).to.be.true
      expect(await proxiedST.hasRole(adminRole, owner.address)).to.be.false

    })

    it("Token Beacon owner should be able to upgrade his proxies, upgrade shouldn't affect state of proxies", async function() {
      //Shareable token beacon
      let deployedProxyAddress = await _factoryContract.createShareableERC721Proxy("ShareableToken","ST",0, owner.address);
      let receipt = await deployedProxyAddress.wait()
      let event = findEvent('ShareableERC721ProxyCreated', receipt)
      let deployAddress = event[0]?.args[0]
      let proxiedST = await ShareableERC721.attach(deployAddress);
      let beaconAddress = await _factoryContract.ShareableERC721BeaconAddress();

      await proxiedST.mint(addr1.address)
      await proxiedST.mint(addr2.address)

      let sBeacon = await BeaconShareableERC721.attach(beaconAddress)
      let sBeaconImplementation = await sBeacon.implementation()
      let redeployedTokeContract = await ShareableERC721v2Test.deploy();
      await sBeacon.update(redeployedTokeContract.address)

      proxiedST = await ShareableERC721v2Test.attach(deployAddress);
      expect(await proxiedST.getIndex2()).to.equal(200)
      expect(await proxiedST.getIndex()).to.equal(2)
      expect(await proxiedST.hasRole(adminRole, owner.address)).to.be.true
      expect(await proxiedST.hasRole(operatorRole, owner.address)).to.be.true
      expect(await proxiedST.hasRole(adminRole, addr1.address)).to.be.false

      //console.log(await proxiedST.getIndex2())
      //console.log(await proxiedST.getIndex())
      await proxiedST.mint(addr1.address)

      // LikeToken Beacon 
      let deployedLProxyAddress = await _factoryContract.createLikeERC721Proxy("LikeERC721","LT",0, owner.address);
      let l_receipt = await deployedLProxyAddress.wait()
      //console.log(l_receipt)
      let l_event = findEvent('LikeERC721ProxyCreated', l_receipt)
      let l_deployAddress = l_event[0]?.args[0]
      //console.log(l_deployAddress)
      let proxiedLT = await LikeERC721.attach(l_deployAddress);

      await proxiedLT.setProjectAddress(deployAddress);
      expect(await proxiedLT.getProjectAddress()).to.be.equal(deployAddress)

      const l_minting = await proxiedLT.connect(addr2).mint(ethers.constants.Zero)
      expect(l_minting).to.emit(proxiedLT, "Transfer").withArgs(ethers.constants.AddressZero, addr2.address, 0)
      expect(l_minting).to.emit(proxiedLT, "Like").withArgs(addr2.address, addr1.address, 0, ethers.constants.AddressZero)
      expect(await proxiedLT.getIndex()).to.equal(ethers.constants.One)

      //Try to update LProxy & check that index is the same after upgrade

      // EndorseToken Beacon
      let deployedEProxyAddress = await _factoryContract.createEndorseERC721Proxy("EndorseERC721","ET",0, owner.address);
      let e_receipt = await deployedEProxyAddress.wait()
      let e_event = findEvent('EndorseERC721ProxyCreated', e_receipt)
      let e_deployAddress = e_event[0]?.args[0]
      let proxiedET = await EndorseableERC721.attach(e_deployAddress)

      await proxiedET.setProjectAddress(deployAddress)
      expect(await proxiedET.getProjectAddress()).to.be.equal(deployAddress)
      expect(await proxiedET.getIndex()).to.be.equal(ethers.constants.Zero)
      const e_minting = await proxiedET.connect(addr1).mint(ethers.constants.Zero)
      expect(await proxiedET.getIndex()).to.be.equal(ethers.constants.One)
      

      //upgrade contact, check that state is still the same
      
    })

  });

  
})