const { inputToConfig } = require("@ethereum-waffle/compiler");
const { Description } = require("@ethersproject/properties");
const { expect } = require("chai");
const { ethers } = require("hardhat");

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

  let owner;
  let addr1;
  let addr2;
  let addrs;

  beforeEach(async function() {

    TokenContract = await ethers.getContractFactory("ShareableERC721");
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    shareableERC721 = await TokenContract.deploy("ShareableToken","ST");
    console.log('contract deployed to', shareableERC721.address);
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
    let tokenId = 001;
    let newTokenId = 002;
    let tokenURI = 'http://example.com/tokens/001';
    //share token, check that it is sent to correct receiver, check that URI is what was expected

    it("Should mint a new token and transfer it to an account", async function() {

      const minting = await shareableERC721.mint(addr1.address, tokenId)

      logEvents(minting)

      expect(minting).to.emit(shareableERC721, "Transfer").withArgs("0x0000000000000000000000000000000000000000", addr1.address, tokenId)

      await shareableERC721.setTokenURI(tokenId, tokenURI)

      expect(await shareableERC721.ownerOf(tokenId)).to.equal(addr1.address);
      expect(await shareableERC721.tokenURI(tokenId)).to.equal(tokenURI);
    });

    it("Should mint token and should share a new token", async function() {

      const minting = await shareableERC721.mint(addr1.address, tokenId)
      await shareableERC721.setTokenURI(tokenId, tokenURI)
      expect(minting).to.emit(shareableERC721, "Transfer").withArgs("0x0000000000000000000000000000000000000000", addr1.address, tokenId)

      const share = await shareableERC721.connect(addr1).share(addr2.address, tokenId, newTokenId);
      logEvents(share)
      expect(share).to.emit(shareableERC721, "Transfer").withArgs("0x0000000000000000000000000000000000000000", addr2.address, newTokenId)
      expect(share).to.emit(shareableERC721, "Share").withArgs(addr1.address, addr2.address, newTokenId)
      //new event required 'share' to denote reminting from A to B

      expect(await shareableERC721.ownerOf(newTokenId)).to.equal(addr2.address);
      expect(await shareableERC721.tokenURI(newTokenId)).to.equal(tokenURI);
    });

    it("Should mint token, should not be shareable by others", async function() {
      await shareableERC721.mint(addr1.address, tokenId)
      await shareableERC721.setTokenURI(tokenId, tokenURI)

      //Attempt to as any other wallet than the token receiver but not contract creator
      await expect(shareableERC721.connect(addr2).share(addr2.address, tokenId, newTokenId)).to.be.revertedWith("Method caller must be the owner of token")
      //Attempt to share as contract creator
      await expect(shareableERC721.share(addr2.address, tokenId, newTokenId)).to.be.revertedWith("Method caller must be the owner of token")
    });

    it("Tokens should not be mintable by other users except contract owner", async function() {
      await expect(shareableERC721.connect(addr1).mint(addr1.address, tokenId)).to.be.revertedWith("Ownable: caller is not the owner")
    });

    it("Tokens should not be transferrable by anyone, unless being minted or shared", async function() {
      await shareableERC721.mint(addr1.address, tokenId)
      await shareableERC721.setTokenURI(tokenId, tokenURI)

      await expect(shareableERC721.connect(addr1).transferFrom(addr1.address, addr2.address, tokenId)).to.be.reverted
    });
  });
})