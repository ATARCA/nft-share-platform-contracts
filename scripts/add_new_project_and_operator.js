const tokenURIBase = 'https://test.api.talkoapp.io/metadata/';
const _ = require("lodash");

const contract_address = "0x94Cf6A9d6D92Ec103504298ABe428f8405C11985"
const novactProjectName = 'Connecta'
const operatorAddress = "0xA86cb4378Cdbc327eF950789c81BcBcc3aa73D21"

async function main() {

  const findEvent = function(eventName, transactionReceipt) {
    return _.filter(transactionReceipt?.events, function(o) {
      return o.event == eventName
    });
  }

  const [deployer] = await ethers.getSigners();

  console.log("Running with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  //get factory contract
  let FactoryContract;
  let _factoryContract;

  FactoryContract = await ethers.getContractFactory("TalkoFactory");
  _factoryContract = FactoryContract.attach(contract_address)

  let novactShareTokenDeployedProxyAddress = await _factoryContract.createShareableERC721Proxy(novactProjectName,"SHARE", deployer.address);
  let novactShareTokenReceipt = await novactShareTokenDeployedProxyAddress.wait()
  let novactShareTokenEvent = findEvent('ShareableERC721ProxyCreated', novactShareTokenReceipt)
  let novactShareTokenDeployAddress = novactShareTokenEvent[0]?.args[0]

  let ShareableERC721 = await ethers.getContractFactory("ShareableERC721");

  //let novactShareTokenDeployAddress = "0x629a5de457c47b3d894a4506ad897ff03d059ff5"
  const novactShareTokenContract = ShareableERC721.attach(novactShareTokenDeployAddress)
  await novactShareTokenContract.setBaseURI(tokenURIBase)

  console.log("Shareable token proxy address: ", novactShareTokenDeployAddress);

  const receipt = await novactShareTokenContract.addOperator(operatorAddress)
  await receipt.wait()
  console.log("operator added");

  let novactLikeTokenDeployedProxyAddress = await _factoryContract.createLikeERC721Proxy(novactProjectName,"LIKE", deployer.address);
  let novactLikeTokenReceipt = await novactLikeTokenDeployedProxyAddress.wait()
  let novactLikeTokenEvent = findEvent('LikeERC721ProxyCreated', novactLikeTokenReceipt)
  let novactLikeTokenDeployAddress = novactLikeTokenEvent[0]?.args[0]

  //let novactLikeTokenDeployAddress = "0x4a89d808272b553982ea917703492f1df3cd0c47"

  //let novactShareTokenDeployAddress = "0x629a5de457c47b3d894a4506ad897ff03d059ff5"
  let LikeERC721 = await ethers.getContractFactory("LikeERC721");
  let proxiedLikeToken = await LikeERC721.attach(novactLikeTokenDeployAddress);
  await proxiedLikeToken.setProjectAddress(novactShareTokenDeployAddress);


}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });