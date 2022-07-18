const { inputToConfig } = require("@ethereum-waffle/compiler");
const { Description } = require("@ethersproject/properties");
const { expect } = require("chai");
const exp = require("constants");
const { ethers, upgrades } = require("hardhat");
const hre = require("hardhat");

const logEvents = async function(calledMethod) {
  const receipt = await calledMethod.wait()
  for (const event of receipt.events) {
    console.log(`Event ${event.event} with args ${event.args}`);
  }
}

describe("Likeable ERC721 contract", function() {

  let LikeTokenContract;
  let instanceLikeTokenContract;

  let EndorseTokenContract;
  let instanceEndorseTokenContract;

  let ContributionTokenContract;
  let instanceContributionTokenContract;

  let deployed_address;

  let owner;
  let addr1;
  let addr2;
  let addrs;

  let tokenURIBase = 'domain/metadata/';

  let s_tokenId = "0x0000000000000000000000000000000000000000";

  beforeEach(async function() {
    
    await hre.network.provider.send("hardhat_reset");
    //Todo: deploy contracts
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    //console.log('owner', owner.address)

    ContributionTokenContract = await ethers.getContractFactory("ShareableERC721");
    instanceContributionTokenContract = await upgrades.deployProxy(ContributionTokenContract,["ShareableToken","ST",owner.address]);
    await instanceContributionTokenContract.deployed()
    //= await ContributionTokenContract.deploy("ShareableToken", "ST")
    instanceContributionTokenContract.setBaseURI(tokenURIBase);

    EndorseTokenContract = await ethers.getContractFactory("EndorseERC721");
    instanceEndorseTokenContract = await upgrades.deployProxy(EndorseTokenContract, ["EndorseERC721", "ET",owner.address]);
    await instanceEndorseTokenContract.deployed()
    //await upgrades.deployProxy(EndorseTokenContract, ["EndorseERC721", "ET"]);
    //await EndorseTokenContract.deploy("EndorseERC721", "ET")

    LikeTokenContract = await ethers.getContractFactory("LikeERC721");
    instanceLikeTokenContract = await upgrades.deployProxy(LikeTokenContract, ["LikeERC721","LT",owner.address]);
    await instanceLikeTokenContract.deployed()
    //await LikeTokenContract.deploy("LikeERC721", "LT")

    await instanceLikeTokenContract.setProjectAddress(instanceContributionTokenContract.address)

    await instanceEndorseTokenContract.setProjectAddress(instanceContributionTokenContract.address)

    //Mint a couple of contributions as contract author
    await instanceContributionTokenContract.mint(addr1.address)
    await instanceContributionTokenContract.mint(addr2.address)
  })

  describe("Deployment", function() {

    it("Contracts should deploy succesfully and have right symbols", async function() {
      expect(await instanceContributionTokenContract.symbol()).to.equal("ST")
      expect(await instanceEndorseTokenContract.symbol()).to.equal("ET")
      expect(await instanceLikeTokenContract.symbol()).to.equal("LT")
      expect(await instanceLikeTokenContract.getProjectAddress()).to.equal(instanceContributionTokenContract.address)
    })
  })

  it("Should be able to like an existing contribution", async function() {
    const e_minting = await instanceLikeTokenContract.connect(addr2).mint(s_tokenId)
    expect(e_minting).to.emit(instanceLikeTokenContract, "Transfer").withArgs("0x0000000000000000000000000000000000000000", addr2.address, s_tokenId)
    expect(e_minting).to.emit(instanceLikeTokenContract, "Like").withArgs(addr2.address, addr1.address, 0, s_tokenId)
  })

  it("Should not be able to like token that doesn't exist", async function() {
    await expect(instanceLikeTokenContract.mint(002)).to.be.revertedWith("Contribution token must exist")
  })

  it("Should not be able to like same contribution twice from same address", async function() {
    //Endorse once
    const e_minting = await instanceLikeTokenContract.connect(addr1).mint(s_tokenId)
    expect(e_minting).to.emit(instanceLikeTokenContract, "Transfer").withArgs("0x0000000000000000000000000000000000000000", addr1.address, 0)
    expect(e_minting).to.emit(instanceLikeTokenContract, "Like").withArgs(addr1.address, addr1.address, 0, s_tokenId)
    //Try to endorse again
    await expect(instanceLikeTokenContract.connect(addr1).mint(s_tokenId)).to.be.revertedWith("Contributions cannot be liked twice")
  })

  it("Should be able to like same contribution from different wallets", async function() {
    //Endorse once
    const e_minting = await instanceLikeTokenContract.connect(addr1).mint(s_tokenId)
    expect(e_minting).to.emit(instanceLikeTokenContract, "Transfer").withArgs("0x0000000000000000000000000000000000000000", addr1.address, 0)
    expect(e_minting).to.emit(instanceLikeTokenContract, "Like").withArgs(addr1.address, addr1.address, 0, s_tokenId)

    //Endorse again
    const e_minting_w2 = await instanceLikeTokenContract.connect(addr2).mint(s_tokenId)
    expect(e_minting_w2).to.emit(instanceLikeTokenContract, "Transfer").withArgs("0x0000000000000000000000000000000000000000", addr2.address, 1)
    expect(e_minting_w2).to.emit(instanceLikeTokenContract, "Like").withArgs(addr2.address, addr1.address, 1, s_tokenId)
  })

  it("Tokens should not be transferrable", async function() {
    await instanceLikeTokenContract.connect(addr1).mint(s_tokenId)
    await expect(instanceLikeTokenContract.connect(addr1).transferFrom(addr1.address, addr2.address, 0)).to.be.revertedWith('Tokens are not transferrable')
    await expect(instanceLikeTokenContract.connect(addr1)["safeTransferFrom(address,address,uint256)"](addr1.address, addr2.address, 0)).to.be.revertedWith('Tokens are not transferrable')
    await expect(instanceLikeTokenContract.connect(addr1)["safeTransferFrom(address,address,uint256,bytes)"](addr1.address, addr2.address, 0, [])).to.be.revertedWith('Tokens are not transferrable')
  });

  it("Only owner should be able to update interface addresses", async function() {
    await expect(instanceLikeTokenContract.connect(addr1).setProjectAddress(instanceContributionTokenContract.address)).to.be.reverted
  })

  it("should be able to like even if already has endorsed a contribution", async function() {
    //Endorse token #0 as addr1
    await instanceEndorseTokenContract.connect(addr1).mint(s_tokenId)
    //Attempt to like the same token as addr1
    await expect(instanceLikeTokenContract.connect(addr1).mint(s_tokenId))
  })

  it("should be able to burn the token and after burning token should not be liked by user", async function() {
    const e_minting = await instanceLikeTokenContract.connect(addr2).mint(s_tokenId)
    expect(await instanceLikeTokenContract.connect(addr1).hasLikedContribution(addr2.address,s_tokenId)).to.equal(true)
    await instanceLikeTokenContract.connect(addr2).burn(0)
    
    expect(await instanceLikeTokenContract.connect(addr1).hasLikedContribution(addr2.address,s_tokenId)).to.equal(false)
    // count of tokens should be now decreased by one, user shouldn't be the owner of the token
  })

  it("only owner should be able to burn his token", async function() {
    const e_minting = await instanceLikeTokenContract.connect(addr2).mint(s_tokenId)
    expect(await instanceLikeTokenContract.connect(addr1).hasLikedContribution(addr2.address,s_tokenId)).to.equal(true)
    await expect(instanceLikeTokenContract.connect(addr1).burn(0)).to.be.revertedWith("Must be owner of token to be able to burn it")
  })

  it("should be able to get metadata of liked contribution from the endorse token", async function() {
    const e_minting = await instanceLikeTokenContract.connect(addr2).mint(s_tokenId)
    deployed_address = instanceContributionTokenContract.address.toLowerCase();
    expect(await instanceLikeTokenContract.tokenURI(0)).to.equal(tokenURIBase+deployed_address+'/0')

    //mint another like against same contribution with different address, should return right metadata
    await instanceLikeTokenContract.connect(addr1).mint(s_tokenId)
    deployed_address = instanceContributionTokenContract.address.toLowerCase();
    expect(await instanceLikeTokenContract.tokenURI(1)).to.equal(tokenURIBase+deployed_address+'/0')
  })

})