const { inputToConfig } = require("@ethereum-waffle/compiler");
const { Description } = require("@ethersproject/properties");
const { expect } = require("chai");
const exp = require("constants");
const { ethers } = require("hardhat");
const hre = require("hardhat");

const logEvents = async function(calledMethod) {
  const receipt = await calledMethod.wait()
  for (const event of receipt.events) {
    console.log(`Event ${event.event} with args ${event.args}`);
  }
}

describe("Endorsable ERC721 contract", function() {

  let EndorsableTokenContract;
  let instanceEndorsableTokenContract;

  let ShareableTokenContract;
  let instanceShareableTokenContract;

  let owner;
  let addr1;
  let addr2;
  let addrs;

  let tokenURIBase = 'http://example.com/tokens/';

  beforeEach(async function() {

    await hre.network.provider.send("hardhat_reset")
    //Todo: deploy contracts
    ShareableTokenContract = await ethers.getContractFactory("ShareableERC721");
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    //console.log('owner', owner.address)

    instanceShareableTokenContract = await ShareableTokenContract.deploy("ShareableToken", "ST")
    instanceShareableTokenContract.setBaseURI(tokenURIBase);

    EndorsableTokenContract = await ethers.getContractFactory("EndorseERC721");
    instanceEndorsableTokenContract = await EndorsableTokenContract.deploy("EndorseERC721", "ET")

    LikeTokenContract = await ethers.getContractFactory("LikeERC721");
    instanceLikeTokenContract = await LikeTokenContract.deploy("LikeERC721", "LT")

    //Set endorse contract interface addresses
    await instanceEndorsableTokenContract.setProjectAddress(instanceShareableTokenContract.address)
    await instanceEndorsableTokenContract.setLikesAddress(instanceLikeTokenContract.address)

    //Set like contract interface addresses
    await instanceLikeTokenContract.setProjectAddress(instanceShareableTokenContract.address)
    await instanceLikeTokenContract.setEndorsesAddress(instanceEndorsableTokenContract.address)

    //Mint a couple of contributions as contract author
    await instanceShareableTokenContract.mint(addr1.address)
    await instanceShareableTokenContract.mint(addr2.address)
  })
  
  describe("Deployment", function() {

    it("Contracts should deploy succesfully and have right symbols, interfaces should be set to correct addresses", async function() {
      expect(await instanceShareableTokenContract.symbol()).to.equal("ST")
      expect(await instanceEndorsableTokenContract.symbol()).to.equal("ET")
      expect(await instanceLikeTokenContract.symbol()).to.equal("LT")

      expect(await instanceEndorsableTokenContract.getProjectAddress()).to.equal(instanceShareableTokenContract.address)
      expect(await instanceEndorsableTokenContract.getLikesAddress()).to.equal(instanceLikeTokenContract.address)
    })
  })

  describe("Token minting (endorsing)", function() {
    let s_tokenId = "0x0000000000000000000000000000000000000000";
    let s_tokenURI = 'http://example.com/tokens/000';

    it("Should be able to endorse existing contribution", async function() {
      const e_minting = await instanceEndorsableTokenContract.connect(addr2).mint(s_tokenId)
      expect(e_minting).to.emit(instanceEndorsableTokenContract, "Transfer").withArgs("0x0000000000000000000000000000000000000000", addr2.address, s_tokenId)
      expect(e_minting).to.emit(instanceEndorsableTokenContract, "Endorse").withArgs(addr2.address, addr1.address, 0, s_tokenId)
    })

    it("Should not be able to endorse token that doesn't exist", async function() {
      await expect(instanceEndorsableTokenContract.mint(002)).to.be.revertedWith("Contribution token must exist")
    })

    it("Should not be able to endorse same contribution twice from same address", async function() {
      //Endorse once
      const e_minting = await instanceEndorsableTokenContract.connect(addr1).mint(s_tokenId)
      expect(e_minting).to.emit(instanceEndorsableTokenContract, "Transfer").withArgs("0x0000000000000000000000000000000000000000", addr1.address, 0)
      expect(e_minting).to.emit(instanceEndorsableTokenContract, "Endorse").withArgs(addr1.address, addr1.address, 0, s_tokenId)
      //Try to endorse again
      await expect(instanceEndorsableTokenContract.connect(addr1).mint(s_tokenId)).to.be.revertedWith("Contributions cannot be endorsed twice")
    })

    it("Should be able to endorse same contribution from different wallets", async function() {      
      //Endorse once
      const e_minting = await instanceEndorsableTokenContract.connect(addr1).mint(s_tokenId)
      expect(e_minting).to.emit(instanceEndorsableTokenContract, "Transfer").withArgs("0x0000000000000000000000000000000000000000", addr1.address, 0)
      expect(e_minting).to.emit(instanceEndorsableTokenContract, "Endorse").withArgs(addr1.address, addr1.address, 0, s_tokenId)

      //Endorse again
      const e_minting_w2 = await instanceEndorsableTokenContract.connect(addr2).mint(s_tokenId)
      expect(e_minting_w2).to.emit(instanceEndorsableTokenContract, "Transfer").withArgs("0x0000000000000000000000000000000000000000", addr2.address, 1)
      expect(e_minting_w2).to.emit(instanceEndorsableTokenContract, "Endorse").withArgs(addr2.address, addr1.address, 1, s_tokenId)
    })

    it("Tokens should not be transferrable", async function() {
      await instanceEndorsableTokenContract.connect(addr1).mint(s_tokenId)
      await expect(instanceEndorsableTokenContract.connect(addr1).transferFrom(addr1.address, addr2.address, 0)).to.be.revertedWith('Tokens are not transferrable')
      await expect(instanceEndorsableTokenContract.connect(addr1)["safeTransferFrom(address,address,uint256)"](addr1.address, addr2.address, 0)).to.be.revertedWith('Tokens are not transferrable')
      await expect(instanceEndorsableTokenContract.connect(addr1)["safeTransferFrom(address,address,uint256,bytes)"](addr1.address, addr2.address, 0, [])).to.be.revertedWith('Tokens are not transferrable')
    });

    it("Only owner should be able to update interface addrersses", async function() {
      await expect(instanceEndorsableTokenContract.connect(addr1).setProjectAddress(instanceShareableTokenContract.address)).to.be.reverted
      await expect(instanceEndorsableTokenContract.connect(addr1).setLikesAddress(instanceLikeTokenContract.address)).to.be.reverted
    })

    it("should not be able to endorse if already has liked a contribution", async function() {
      //Like token #0 as addr1
      await instanceLikeTokenContract.connect(addr1).mint(s_tokenId)
      //Attempt to endrose the same token as addr1
      await expect(instanceEndorsableTokenContract.connect(addr1).mint(s_tokenId)).to.be.reverted
    })

    it("should be able to burn the token and after burning token should not be endorsed by user", async function() {
      const e_minting = await instanceEndorsableTokenContract.connect(addr2).mint(s_tokenId)
      expect(await instanceEndorsableTokenContract.connect(addr1).hasEndorsedContribution(addr2.address,s_tokenId)).to.equal(true)
      await instanceEndorsableTokenContract.connect(addr2).burn(0)
      
      expect(await instanceEndorsableTokenContract.connect(addr1).hasEndorsedContribution(addr2.address,s_tokenId)).to.equal(false)
      // count of tokens should be now decreased by one, user shouldn't be the owner of the token
    })

    it("only owner should be able to burn his token", async function() {
      const e_minting = await instanceEndorsableTokenContract.connect(addr2).mint(s_tokenId)
      expect(await instanceEndorsableTokenContract.connect(addr1).hasEndorsedContribution(addr2.address,s_tokenId)).to.equal(true)
      await expect(instanceEndorsableTokenContract.connect(addr1).burn(0)).to.be.revertedWith("Must be owner of token to be able to burn it")
    })

    // should be able to get metadata of endorsed contribution from the endorse token

    it("should be able to get metadata of endorsed contribution from the endorse token", async function() {
      const e_minting = await instanceEndorsableTokenContract.connect(addr2).mint(s_tokenId)
      expect(await instanceEndorsableTokenContract.tokenURI(0)).to.equal("http://example.com/tokens/0")
    })

  })
})