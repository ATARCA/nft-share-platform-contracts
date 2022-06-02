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

describe("Likeable ERC721 contract", function() {

  let LikeTokenContract;
  let instanceLikeTokenContract;

  let EndorseTokenContract;
  let instanceEndorseTokenContract;

  let ContributionTokenContract;
  let instanceContributionTokenContract;

  let owner;
  let addr1;
  let addr2;
  let addrs;

  beforeEach(async function() {

    //Todo: deploy contracts
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    console.log('owner', owner.address)

    ContributionTokenContract = await ethers.getContractFactory("ShareableERC721");
    instanceContributionTokenContract = await ContributionTokenContract.deploy("ShareableToken", "ST")

    EndorseTokenContract = await ethers.getContractFactory("EndorseERC721");
    instanceEndorseTokenContract = await EndorseTokenContract.deploy("EndorseERC721", "ET")

    LikeTokenContract = await ethers.getContractFactory("LikeERC721");
    instanceLikeTokenContract = await LikeTokenContract.deploy("LikeERC721", "LT")

    await instanceLikeTokenContract.setProjectAddress(instanceContributionTokenContract.address)
    await instanceLikeTokenContract.setEndorsesAddress(instanceEndorseTokenContract.address)
  })

  describe("Deployment", function() {

    it("Contracts should deploy succesfully and have right symbols", async function() {
      expect(await instanceContributionTokenContract.symbol()).to.equal("ST")
      expect(await instanceEndorseTokenContract.symbol()).to.equal("ET")
      expect(await instanceLikeTokenContract.symbol()).to.equal("LT")
      expect(await instanceLikeTokenContract.getProjectAddress()).to.equal(instanceContributionTokenContract.address)
      expect(await instanceLikeTokenContract.getEndorsesAddress()).to.equal(instanceEndorseTokenContract.address)
      
    })
  })


  // should be able to mint

  // shouldn't be able to like if no contribution token

  // shouldn't be able to like twice

  // should not be transferable

  // should no be able to like if already has endorsed

  // should be able to burn the token and after burning token should not be liked anymore by the user

  // should be able to get metadata of liked contribution from the like token

})