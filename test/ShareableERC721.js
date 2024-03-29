const { inputToConfig } = require("@ethereum-waffle/compiler");
const { Description } = require("@ethersproject/properties");
const { expect } = require("chai");
const { keccak256, toUtf8Bytes, formatBytes32String } = require("ethers/lib/utils");
const { ethers, upgrades } = require("hardhat");
const hre = require("hardhat");
const { isFunctionLike } = require("typescript");

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

  let categoryName = 'Community hero of the month'

  beforeEach(async function() {

    await hre.network.provider.send("hardhat_reset")
    TokenContract = await ethers.getContractFactory("ShareableERC721");
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    shareableERC721 = await upgrades.deployProxy(TokenContract,["ShareableToken","ST", owner.address]);
    await shareableERC721.deployed();
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
    let baseAddress = ethers.constants.AddressZero
    let tokenId     = ethers.constants.Zero    
    let newTokenId  = ethers.constants.One

    it("Should mint a new token and transfer it to an account", async function() {
      const minting = await shareableERC721.mint(addr1.address, categoryName)
      deployed_address = shareableERC721.address.toLowerCase();
      expect(minting).to.emit(shareableERC721, "Transfer").withArgs(baseAddress, addr1.address, tokenId)
      expect(await shareableERC721.ownerOf(tokenId)).to.equal(addr1.address);
      expect(await shareableERC721.tokenURI(tokenId)).to.equal(tokenURIBase+deployed_address+'/0');
    });

    it("is original token and derived from token should work for minted and shared tokens", async function() {
      const minting = await shareableERC721.mint(addr1.address, categoryName)
      expect(await shareableERC721.isOriginalToken(tokenId)).to.equal(true)
      expect(await shareableERC721.isDerivedFrom(tokenId)).to.equal(tokenId)

      const share = await shareableERC721.connect(addr1).share(addr2.address, tokenId);
      expect(await shareableERC721.isOriginalToken(newTokenId)).to.equal(false)
      expect(await shareableERC721.isDerivedFrom(newTokenId)).to.equal(tokenId)
    })

    it("is original token and derived from token should revert if token doesn't exist", async function(){
      await expect(shareableERC721.isOriginalToken(tokenId)).to.be.revertedWith("ShareableERC721: token doesn't exist")
      await expect(shareableERC721.isDerivedFrom(tokenId)).to.be.revertedWith("ShareableERC721: token doesn't exist")
    })

    it("Should mint token and should share a new token", async function() {
      const minting = await shareableERC721.mint(addr1.address, categoryName)
      deployed_address = shareableERC721.address.toLowerCase();
      expect(minting).to.emit(shareableERC721, "Mint").withArgs(owner.address, addr1.address, tokenId, categoryName)
      expect(minting).to.emit(shareableERC721, "Transfer").withArgs(baseAddress, addr1.address, tokenId)
      
      const share = await shareableERC721.connect(addr1).share(addr2.address, tokenId);
      expect(share).to.emit(shareableERC721, "Transfer").withArgs(baseAddress, addr2.address, newTokenId)
      expect(share).to.emit(shareableERC721, "Share").withArgs(addr1.address, addr2.address, newTokenId, tokenId)
      expect(await shareableERC721.ownerOf(newTokenId)).to.equal(addr2.address);
      expect(await shareableERC721.tokenURI(newTokenId)).to.equal(tokenURIBase+deployed_address+'/1');
    });

    it("Should mint token, should not be shareable by others", async function() {
      await shareableERC721.mint(addr1.address, categoryName)
      //Attempt to as any other wallet than the token receiver but not contract creator
      await expect(shareableERC721.connect(addr2).share(addr2.address, tokenId)).to.be.revertedWith("Method caller must be the owner of token")
      //Attempt to share as contract creator
      await expect(shareableERC721.share(addr2.address, tokenId)).to.be.revertedWith("Method caller must be the owner of token")
    });

    it("Tokens should not be mintable by other users except contract owner", async function() {
      await expect(shareableERC721.connect(addr1).mint(addr1.address, categoryName)).to.be.reverted
    });

    it("Tokens should not be transferrable by anyone, unless being minted or shared", async function() {
      await shareableERC721.mint(addr1.address, categoryName)
      await expect(shareableERC721.connect(addr1).transferFrom(addr1.address, addr2.address, tokenId)).to.be.revertedWith('Tokens are not transferrable')
      await expect(shareableERC721["safeTransferFrom(address,address,uint256)"](owner.address, addr1.address, 0)).to.be.revertedWith('Tokens are not transferrable')
      await expect(shareableERC721["safeTransferFrom(address,address,uint256,bytes)"](owner.address, addr1.address, 0, [])).to.be.revertedWith('Tokens are not transferrable')
    }); 

    it("Contract deployer should be able to promote and demote", async function() {
      await shareableERC721.addOperator(addr1.address)
      expect(await shareableERC721.hasRole(keccak256(toUtf8Bytes("OPERATOR_ROLE")),addr1.address)).to.be.true
      await shareableERC721.removeOperator(addr1.address)
      expect(await shareableERC721.hasRole(keccak256(toUtf8Bytes("OPERATOR_ROLE")),addr1.address)).to.be.false

      await shareableERC721.addAdmin(addr1.address)
      expect(await shareableERC721.hasRole(ethers.constants.HashZero, addr1.address)).to.be.true
      await shareableERC721.removeAdmin(addr1.address)
      expect(await shareableERC721.hasRole(ethers.constants.HashZero, addr1.address)).to.be.false
    })

    it("Promoted admin users can promote other users", async function() {
      await shareableERC721.addAdmin(addr1.address)
      expect(await shareableERC721.hasRole(ethers.constants.HashZero, addr1.address)).to.be.true
      await shareableERC721.connect(addr1).addOperator(addr2.address)
      expect(await shareableERC721.hasRole(keccak256(toUtf8Bytes("OPERATOR_ROLE")),addr2.address)).to.be.true

      await shareableERC721.connect(addr1).addAdmin(addr2.address)
      expect(await shareableERC721.hasRole(ethers.constants.HashZero, addr2.address)).to.be.true
    })

    it("Users whom are not admins cannot promote other users", async function() {
      await expect(shareableERC721.connect(addr1).addOperator(addr2.address)).to.be.reverted
      await expect(shareableERC721.connect(addr1).addAdmin(addr2.address)).to.be.reverted
    })

    it("only owner should be able to burn his token", async function() {
      await shareableERC721.mint(addr1.address, categoryName)
      await expect(shareableERC721.connect(addr2).burn(0)).to.be.revertedWith("Must be owner of token to be able to burn it")
      const burning = await shareableERC721.connect(addr1).burn(0)
      expect(burning).to.emit(shareableERC721, "Transfer").withArgs(addr1.address, ethers.constants.AddressZero, 0)
    })
  });
})