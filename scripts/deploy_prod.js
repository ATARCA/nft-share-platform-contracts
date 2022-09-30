const tokenURIBase = 'https://api.talkoapp.io/metadata/';
const _ = require("lodash");


async function main() {

  const findEvent = function(eventName, transactionReceipt) {
    return _.filter(transactionReceipt?.events, function(o) {
      return o.event == eventName
    });
  }

  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());
  
  const projectName = 'Streamr'
  const novactProjectName = 'Connecta'

  let ShareableERC721;
  let _shareableERC721;
  let LikeERC721;
  let _likeERC721;
  let EndorseableERC721;
  let _endorseableERC721;

  let FactoryContract;
  let _factoryContract;

  console.log("Deploying ShareableERC721");
  ShareableERC721 = await ethers.getContractFactory("ShareableERC721");
  _shareableERC721 = await ShareableERC721.deploy();
  await _shareableERC721.deployed()
  console.log('ShareableERC721 instance address', _shareableERC721.address)
  console.log("Deploying ShareableERC721-DONE");

  console.log("Deploying LikeERC721");
  LikeERC721 = await ethers.getContractFactory("LikeERC721");
  _likeERC721 = await LikeERC721.deploy();
  await _likeERC721.deployed()
  console.log('LikeERC721 instance address', _likeERC721.address)
  console.log("Deploying LikeERC721-DONE");

  console.log("Deploying EndorseERC721");
  EndorseableERC721 = await ethers.getContractFactory("EndorseERC721");
  _endorseableERC721 = await EndorseableERC721.deploy();
  await _endorseableERC721.deployed()
  console.log('EndorseERC721 instance address', _endorseableERC721.address)
  console.log("Deploying EndorseERC721-DONE");

  FactoryContract = await ethers.getContractFactory("TalkoFactory");
  _factoryContract = await FactoryContract.deploy(_shareableERC721.address, _likeERC721.address, _endorseableERC721.address);
  await _factoryContract.deployed()

  console.log("Factory address: ", _factoryContract.address);

  // Streamr pilot specific instances

  let shareableTokenDeployedProxyAddress = await _factoryContract.createShareableERC721Proxy(projectName,"AWARD", deployer.address);
  let shareableTokenReceipt = await shareableTokenDeployedProxyAddress.wait()
  let shareableTokenEvent = findEvent('ShareableERC721ProxyCreated', shareableTokenReceipt)
  let shareableTokenDeployAddress = shareableTokenEvent[0]?.args[0]

  const shareableTokenContract = ShareableERC721.attach(shareableTokenDeployAddress)
  const transaction = await shareableTokenContract.setBaseURI(tokenURIBase)

  console.log("Shareable token proxy address: ", shareableTokenDeployAddress);

  let likeTokenDeployedProxyAddress = await _factoryContract.createLikeERC721Proxy(projectName,"LIKE", deployer.address);
  let likeTokenReceipt = await likeTokenDeployedProxyAddress.wait()
  let likeTokenEvent = findEvent('LikeERC721ProxyCreated', likeTokenReceipt)
  let likeTokenDeployAddress = likeTokenEvent[0]?.args[0]
  let proxiedLikeToken = await LikeERC721.attach(likeTokenDeployAddress);
  await proxiedLikeToken.setProjectAddress(shareableTokenDeployAddress);

  console.log("LikeERC721 token proxy address: ", likeTokenDeployAddress);

  let endorseTokenDeployedProxyAddress = await _factoryContract.createEndorseERC721Proxy(projectName,"ENDORSE", deployer.address);
  let endorseTokenReceipt = await endorseTokenDeployedProxyAddress.wait()
  let endorseTokenEvent = findEvent('EndorseERC721ProxyCreated', endorseTokenReceipt)
  let endorseTokenDeployAddress = endorseTokenEvent[0]?.args[0]
  let proxiedEndorseToken = await EndorseableERC721.attach(endorseTokenDeployAddress)
  await proxiedEndorseToken.setProjectAddress(shareableTokenDeployAddress)

  console.log("EndorseERC721 token proxy address: ", endorseTokenDeployAddress);

  // Novact pilot specific instances
  
  /*let novactShareTokenDeployedProxyAddress = await _factoryContract.createShareableERC721Proxy(novactProjectName,"SHARE", deployer.address);
  let novactShareTokenReceipt = await novactShareTokenDeployedProxyAddress.wait()
  let novactShareTokenEvent = findEvent('ShareableERC721ProxyCreated', novactShareTokenReceipt)
  let novactShareTokenDeployAddress = novactShareTokenEvent[0]?.args[0]

  const novactShareTokenContract = ShareableERC721.attach(novactShareTokenDeployAddress)
  await novactShareTokenContract.setBaseURI(tokenURIBase)

  console.log("Shareable token proxy address: ", novactShareTokenDeployAddress);

  let novactLikeTokenDeployedProxyAddress = await _factoryContract.createLikeERC721Proxy(novactProjectName,"LIKE", deployer.address);
  let novactLikeTokenReceipt = await novactLikeTokenDeployedProxyAddress.wait()
  let novactLikeTokenEvent = findEvent('LikeERC721ProxyCreated', novactLikeTokenReceipt)
  let novactLikeTokenDeployAddress = novactLikeTokenEvent[0]?.args[0]
  await LikeERC721.attach(novactLikeTokenDeployAddress);
  await proxiedLikeToken.setProjectAddress(novactShareTokenDeployAddress);

  console.log("LikeERC721 token proxy address: ", novactLikeTokenDeployAddress);*/

  //Attempt to verify template contracts
  try {
    await hre.run("verify:verify", {
      address: _shareableERC721.address
    }); 
  }
  catch(e) {
    console.log('verification failed')
    console.log(e)
  }

  try {
    await hre.run("verify:verify", {
      address: _likeERC721.address
    });
  }
  catch(e) {
    console.log('verification failed')
    console.log(e)
  }

  try {
    await hre.run("verify:verify", {
      address: _endorseableERC721.address
    });
  }
  catch(e) {
    console.log('verification failed')
    console.log(e)
  }

  try {
    //Attempt verifying deployed factory contract
    await hre.run("verify:verify", {
      address: _factoryContract.address,
      constructorArguments: [
        _shareableERC721.address,
        _likeERC721.address,
        _endorseableERC721.address
      ],
    });   
  }
  catch(e) {
    console.log('verification failed')
    console.log(e)
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });