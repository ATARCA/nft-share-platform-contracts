const tokenURIBase = 'domain/metadata/';


async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());
  
  ShareableTokenContract = await ethers.getContractFactory("ShareableERC721");
  instanceShareableTokenContract = await ShareableTokenContract.deploy("ShareableToken", "Streamr Contribution Token")
  instanceShareableTokenContract.setBaseURI(tokenURIBase);

  EndorsableTokenContract = await ethers.getContractFactory("EndorseERC721");
  instanceEndorsableTokenContract = await EndorsableTokenContract.deploy("EndorseERC721", "Streamr Endorsement Token")

  LikeTokenContract = await ethers.getContractFactory("LikeERC721");
  instanceLikeTokenContract = await LikeTokenContract.deploy("LikeERC721", "Streamr Like Token")

  console.log("Contribution token address:", instanceShareableTokenContract.address);
  console.log("Endorsement token address:", instanceEndorsableTokenContract.address);
  console.log("Like token address:", instanceLikeTokenContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });