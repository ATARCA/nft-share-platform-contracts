const { inputToConfig } = require("@ethereum-waffle/compiler");
const { Description } = require("@ethersproject/properties");
const { expect } = require("chai");
const { ethers } = require("hardhat");

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

      await shareableERC721.mint(addr1.address, tokenId)
      await shareableERC721.setTokenURI(tokenId, tokenURI)

      expect(await shareableERC721.ownerOf(tokenId)).to.equal(addr1.address);
      expect(await shareableERC721.tokenURI(tokenId)).to.equal(tokenURI);
    });

    it("Should mint token and should share a new token", async function() {

      await shareableERC721.mint(addr1.address, tokenId)
      await shareableERC721.setTokenURI(tokenId, tokenURI)

      await shareableERC721.share(addr2.address, tokenId, newTokenId);

      expect(await shareableERC721.ownerOf(newTokenId)).to.equal(addr2.address);
      expect(await shareableERC721.tokenURI(newTokenId)).to.equal(tokenURI);
    });
  });
})