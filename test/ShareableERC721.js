const { inputToConfig } = require("@ethereum-waffle/compiler");
const { Description } = require("@ethersproject/properties");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const hre = require("hardhat");

//Todo: check that events are fired correctly

//Todo: abstract to a helper library
const logEvents = async function(calledMethod) {
  const receipt = await calledMethod.wait()
  for (const event of receipt.events) {
    console.log(`Event ${event.event} with args ${event.args}`);
  }
}

describe("Shareable ERC 721 contract", function() {

  let TokenContract;
  let shareableERC721;
  let deployed_address;

  let owner;
  let addr1;
  let addr2;
  let addrs;
  let tokenURIBase

  beforeEach(async function() {

    await hre.network.provider.send("hardhat_reset")
    TokenContract = await ethers.getContractFactory("ShareableERC721");
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    shareableERC721 = await TokenContract.deploy("ShareableToken","ST");
    deployed_address = shareableERC721.address;

    tokenURIBase = 'domain/metadata/';
    shareableERC721.setBaseURI(tokenURIBase);
  }); 

  describe("Deployment", function() {
 
    it("Should be set the right symbol", async function() {
      expect(await shareableERC721.symbol()).to.equal("ST");
    });

    it("Should be set the right token name", async function() {
      expect(await shareableERC721.name()).to.equal("ShareableToken");
    });
  });

  describe("Distribution and sharing", function() {
    //mint token, set URIcontent
    //check that receiver gets it and uri content is what was expected
    let baseAddress = "0x0000000000000000000000000000000000000000";
    let tokenId     = "0x0000000000000000000000000000000000000000";    
    let newTokenId  = "0x0000000000000000000000000000000000000001";

    it("Should mint a new token and transfer it to an account", async function() {
      const minting = await shareableERC721.mint(addr1.address)
      deployed_address = shareableERC721.address.toLowerCase();
      //logEvents(minting)
      expect(minting).to.emit(shareableERC721, "Transfer").withArgs(baseAddress, addr1.address, tokenId)
      expect(await shareableERC721.ownerOf(tokenId)).to.equal(addr1.address);
      expect(await shareableERC721.tokenURI(tokenId)).to.equal(tokenURIBase+deployed_address+'/0');
    });

    it("Should mint token and should share a new token", async function() {
      const minting = await shareableERC721.mint(addr1.address)
      //logEvents(minting)
      deployed_address = shareableERC721.address.toLowerCase();
      expect(minting).to.emit(shareableERC721, "Transfer").withArgs(baseAddress, addr1.address, tokenId)
      
      const share = await shareableERC721.connect(addr1).share(addr2.address, tokenId);
      //logEvents(share)
      expect(share).to.emit(shareableERC721, "Transfer").withArgs(tokenId, addr2.address, newTokenId)
      expect(share).to.emit(shareableERC721, "Share").withArgs(addr1.address, addr2.address, newTokenId, tokenId)
      expect(await shareableERC721.ownerOf(newTokenId)).to.equal(addr2.address);
      expect(await shareableERC721.tokenURI(newTokenId)).to.equal(tokenURIBase+deployed_address+'/1');
    });

    it("Should mint token, should not be shareable by others", async function() {
      await shareableERC721.mint(addr1.address)
      //Attempt to as any other wallet than the token receiver but not contract creator
      await expect(shareableERC721.connect(addr2).share(addr2.address, tokenId)).to.be.revertedWith("Method caller must be the owner of token")
      //Attempt to share as contract creator
      await expect(shareableERC721.share(addr2.address, tokenId)).to.be.revertedWith("Method caller must be the owner of token")
    });

    it("Tokens should not be mintable by other users except contract owner", async function() {
      await expect(shareableERC721.connect(addr1).mint(addr1.address)).to.be.revertedWith("Ownable: caller is not the owner")
    });

    it("Tokens should not be transferrable by anyone, unless being minted or shared", async function() {
      await shareableERC721.mint(addr1.address)
      await expect(shareableERC721.connect(addr1).transferFrom(addr1.address, addr2.address, tokenId)).to.be.revertedWith('Tokens are not transferrable')
      await expect(shareableERC721["safeTransferFrom(address,address,uint256)"](owner.address, addr1.address, 0)).to.be.revertedWith('Tokens are not transferrable')
      await expect(shareableERC721["safeTransferFrom(address,address,uint256,bytes)"](owner.address, addr1.address, 0, [])).to.be.revertedWith('Tokens are not transferrable')
    }); 
  });
})