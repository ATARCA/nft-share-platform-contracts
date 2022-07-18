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

  let tokenId     = "0x0000000000000000000000000000000000000000";    
  let newTokenId  = "0x0000000000000000000000000000000000000001";

  let operatorRole = keccak256(ethers.utils.toUtf8Bytes("OPERATOR_ROLE"));
  let adminRole = ethers.constants.HashZero

  beforeEach(async function() {

    await hre.network.provider.send("hardhat_reset");
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    //console.log('@@@@@@@')
    //console.log('owner wallet is', owner.address)
    //console.log('@@@@@@@')

    BeaconShareableERC721 = await ethers.getContractFactory("ShareableTokenBeacon");

    ShareableERC721 = await ethers.getContractFactory("ShareableERC721");
    _shareableERC721 = await ShareableERC721.deploy();
    await _shareableERC721.deployed()


    ShareableERC721v2Test = await ethers.getContractFactory("ShareableERC721v2Test");

    //BeaconShareableERC721 = await ethers.getContractFactory("ShareableTokenBeacon");
    //_beaconShareableERC721  = await BeaconShareableERC721.deploy(_shareableERC721.address);

    LikeERC721 = await ethers.getContractFactory("LikeERC721");
    _likeERC721 = await LikeERC721.deploy();
    await _likeERC721.deployed()

    //BeaconLikeERC721 = await ethers.getContractAt("LikeTokenBeacon");
    //_beaconLikeERC721 = await ethers.deploy(_likeERC721.address);

    EndorseableERC721 = await ethers.getContractFactory("EndorseERC721");
    _endorseableERC721 = await EndorseableERC721.deploy();
    await _endorseableERC721.deployed()

    //BeaconEndorseableERC721 = await ethers.getContractAt("EndorseTokenBeacon");
    //_beaconEndorseableERC721 = await BeaconEndorseableERC721.deploy(_endorseableERC721.address);

    FactoryContract = await ethers.getContractFactory("TalkoFactory");
    _factoryContract = await FactoryContract.deploy(_shareableERC721.address, _likeERC721.address, _endorseableERC721.address);
    await _factoryContract.deployed()

    //await shareableERC721.initialize("ShareableToken","ST");
    //await shareableERC721.deployed();
    //deployed_address = shareableERC721.address;
    
    //deployedTokenBeacon = await TokenBeacon.deploy(deployed_address);
    //console.log('Owner of beacon', await deployedTokenBeacon.owner())

    //deploy ShareableERC721 again
    
    //redeployedShareableERC721 = await TokenContract.deploy()

    //Deploy factory



    //tokenURIBase = 'domain/metadata/';
    //shareableERC721.setBaseURI(tokenURIBase);

    //Deploy all token contracts
    //Deploy all beacons
  }); 

  describe("Deployment", function() {
 
    //Setup a factory
    //Try to createSProxy

    //mint couple of tokens

    //update beacon
    //check status of proxy
    it("Proxy can be deployed and has correct arguments", async function() {
      let deployedProxyAddress = await _factoryContract.createSProxy("ShareableToken","ST",0, owner.address);
      let receipt = await deployedProxyAddress.wait()
      
      let event = _.filter(receipt?.events, function(o) {
        return o.event === 'SProxyCreated'
      });

      let deployAddress = event[0]?.args[0]
      expect(deployedProxyAddress).to.emit(_factoryContract, "SProxyCreated").withArgs(deployAddress, owner.address, "ST")
    });

    it("Deployed proxy can be interacted with", async function() {
      //Mint a couple of tokens
      //check that tokens got minted

      let deployedProxyAddress = await _factoryContract.createSProxy("ShareableToken","ST",0, owner.address);
      let receipt = await deployedProxyAddress.wait()
      
      let event = _.filter(receipt?.events, function(o) {
        return o.event === 'SProxyCreated'
      });
      //console.log('found event', event[0]?.args)

      let deployAddress = event[0]?.args[0]
      let proxiedST = await ShareableERC721.attach(deployAddress);

      await proxiedST.mint(addr1.address)
      await proxiedST.mint(addr2.address)
      expect(await proxiedST.ownerOf(tokenId)).to.equal(addr1.address);
    })

    it("Deploy proxy to different owner, deployer shouldn't have rights to proxy ", async function() {
      let deployedProxyAddress = await _factoryContract.createSProxy("ShareableToken","ST",0, addr1.address);
      let receipt = await deployedProxyAddress.wait()
      
      let event = _.filter(receipt?.events, function(o) {
        return o.event === 'SProxyCreated'
      });

      let deployAddress = event[0]?.args[0]
      let proxiedST = await ShareableERC721.attach(deployAddress);
      await expect(proxiedST.mint(addr1.address)).to.be.reverted

      expect(await proxiedST.hasRole(adminRole, addr1.address)).to.be.true
      expect(await proxiedST.hasRole(operatorRole, addr1.address)).to.be.true
      expect(await proxiedST.hasRole(adminRole, owner.address)).to.be.false

    })

    it("Token Beacon owner should be able to upgrade proxies, upgrade shouldn't affect state of proxies", async function() {
      let deployedProxyAddress = await _factoryContract.createSProxy("ShareableToken","ST",0, owner.address);
      let receipt = await deployedProxyAddress.wait()

      //console.log(_factoryContract)
      
      let event = _.filter(receipt?.events, function(o) {
        return o.event === 'SProxyCreated'
      });
      //console.log('found event', event[0]?.args)

      let deployAddress = event[0]?.args[0]
      //console.log('deploy address', deployAddress)
      let proxiedST = await ShareableERC721.attach(deployAddress);

      await proxiedST.mint(addr1.address)
      await proxiedST.mint(addr2.address)

      let beaconAddress = await _factoryContract.SBeaconAddress();
      //console.log(beaconAddress)
      
      let sBeacon = await BeaconShareableERC721.attach(beaconAddress)
      let sBeaconImplementation = await sBeacon.implementation()
      //console.log('pre-update address', sBeaconImplementation)

      let redeployedTokeContract = await ShareableERC721v2Test.deploy();

      let update = await sBeacon.update(redeployedTokeContract.address)
      logEvents(update)
      //console.log('post upgrade address', await sBeacon.implementation())

      proxiedST = await ShareableERC721v2Test.attach(deployAddress);
      expect(await proxiedST.getIndex2()).to.equal(200)
      expect(await proxiedST.getIndex()).to.equal(2)
      expect(await proxiedST.hasRole(adminRole, owner.address)).to.be.true
      expect(await proxiedST.hasRole(operatorRole, owner.address)).to.be.true
      expect(await proxiedST.hasRole(adminRole, addr1.address)).to.be.false

      //console.log(await proxiedST.getIndex2())
      //console.log(await proxiedST.getIndex())
      await proxiedST.mint(addr1.address)
    })
  });

  
})