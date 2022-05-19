const { inputToConfig } = require("@ethereum-waffle/compiler");
const { Description } = require("@ethersproject/properties");
const { expect } = require("chai");
const exp = require("constants");
const { ethers } = require("hardhat");

const logEvents = async function(calledMethod) {
  const receipt = await calledMethod.wait()
  for (const event of receipt.events) {
    console.log(`Event ${event.event} with args ${event.args}`);
  }
}

describe("Endorsable ERC721 contract", function() {

  let EndorsableTokenContract;
  let instanceEncordsableTokenContract;

  let ShareableTokenContract;
  let instanceShareableTokenContract;

  let owner;
  let addr1;
  let addr2;
  let addrs;

  beforeEach(async function() {

    //Todo: deploy contracts
    ShareableTokenContract = await ethers.getContractFactory("ShareableERC721");
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    console.log('owner', owner.address)

    instanceShareableTokenContract = await ShareableTokenContract.deploy("ShareableToken", "ST")

    EndorsableTokenContract = await ethers.getContractFactory("EndorsableERC721");
    instanceEncordsableTokenContract = await EndorsableTokenContract.deploy("EndorsableERC721", "ET", instanceShareableTokenContract.address)
  })
  
  describe("Deployment", function() {

    it("Contracts should deploy succesfully and have right symbols", async function() {
      expect(await instanceShareableTokenContract.symbol()).to.equal("ST")
      expect(await instanceEncordsableTokenContract.symbol()).to.equal("ET")
    })
  })

  describe("Token minting (endorsing)", function() {
    let s_tokenId = 001;
    let s_tokenURI = 'http://example.com/tokens/001';

    it("Should be able to endorse existing contribution", async function() {
      const minting = await instanceShareableTokenContract.mint(addr1.address, s_tokenId)
      expect(minting).to.emit(instanceShareableTokenContract, "Transfer").withArgs("0x0000000000000000000000000000000000000000", addr1.address, s_tokenId)

      const e_minting = await instanceEncordsableTokenContract.mint(s_tokenId)
      logEvents(e_minting)
      expect(e_minting).to.emit(instanceEncordsableTokenContract, "Transfer").withArgs("0x0000000000000000000000000000000000000000", owner.address, 0)
      expect(e_minting).to.emit(instanceEncordsableTokenContract, "Endorse").withArgs(owner.address, addr1.address, 0, s_tokenId)
    })

    it("Should not be able to endorse token that doesn't exist", async function() {
      const minting = await instanceShareableTokenContract.mint(addr1.address, s_tokenId)
      expect(minting).to.emit(instanceShareableTokenContract, "Transfer").withArgs("0x0000000000000000000000000000000000000000", addr1.address, s_tokenId)
      await expect(instanceEncordsableTokenContract.mint(002)).to.be.revertedWith("Contribution token must exist")
    })

    it("Should not be able to endorse same contribution twice from same wallet", async function() {
      const minting = await instanceShareableTokenContract.mint(addr1.address, s_tokenId)
      expect(minting).to.emit(instanceShareableTokenContract, "Transfer").withArgs("0x0000000000000000000000000000000000000000", addr1.address, s_tokenId)
      //Endorse once
      const e_minting = await instanceEncordsableTokenContract.mint(s_tokenId)
      expect(e_minting).to.emit(instanceEncordsableTokenContract, "Transfer").withArgs("0x0000000000000000000000000000000000000000", owner.address, 0)
      expect(e_minting).to.emit(instanceEncordsableTokenContract, "Endorse").withArgs(owner.address, addr1.address, 0, s_tokenId)
      //Try to endorse again
      await expect(instanceEncordsableTokenContract.mint(s_tokenId)).to.be.revertedWith("Contributions cannot be endorsed twice")
    })

    it("Should be able to endorse same contribution from different wallets", async function() {
      const minting = await instanceShareableTokenContract.mint(addr1.address, s_tokenId)
      expect(minting).to.emit(instanceShareableTokenContract, "Transfer").withArgs("0x0000000000000000000000000000000000000000", addr1.address, s_tokenId)
      
      //Endorse once
      const e_minting = await instanceEncordsableTokenContract.mint(s_tokenId)
      expect(e_minting).to.emit(instanceEncordsableTokenContract, "Transfer").withArgs("0x0000000000000000000000000000000000000000", owner.address, 0)
      expect(e_minting).to.emit(instanceEncordsableTokenContract, "Endorse").withArgs(owner.address, addr1.address, 0, s_tokenId)

      //Endorse again
      const e_minting_w2 = await instanceEncordsableTokenContract.connect(addr2).mint(s_tokenId)
      expect(e_minting_w2).to.emit(instanceEncordsableTokenContract, "Transfer").withArgs("0x0000000000000000000000000000000000000000", addr2.address, 1)
      expect(e_minting_w2).to.emit(instanceEncordsableTokenContract, "Endorse").withArgs(addr2.address, addr1.address, 1, s_tokenId)
    })

    it("Tokens should not be transferrable", async function() {
      const minting = await instanceShareableTokenContract.mint(addr1.address, s_tokenId)
      
      await instanceEncordsableTokenContract.mint(s_tokenId)
      await expect(instanceEncordsableTokenContract.transferFrom(owner.address, addr1.address, 0)).to.be.revertedWith('Tokens are not transferrable')
      await expect(instanceEncordsableTokenContract["safeTransferFrom(address,address,uint256)"](owner.address, addr1.address, 0)).to.be.revertedWith('Tokens are not transferrable')
      await expect(instanceEncordsableTokenContract["safeTransferFrom(address,address,uint256,bytes)"](owner.address, addr1.address, 0, [])).to.be.revertedWith('Tokens are not transferrable')
    });


  })
})