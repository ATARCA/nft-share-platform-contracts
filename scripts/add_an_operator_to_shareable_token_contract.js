const tokenURIBase = 'domain/metadata/';
const _ = require("lodash");

const contract_address = "0xbC22318AbFB3e3e064192D2e379B77C140AE827D"
const wallet_address_of_new_operator = "0x7a0fE829609EB9AC80c5a60E46FFD5Cf3d57B902"

async function main() {

  const findEvent = function(eventName, transactionReceipt) {
    return _.filter(transactionReceipt?.events, function(o) {
      return o.event == eventName
    });
  }

  const [deployer] = await ethers.getSigners();

  console.log("Running with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  let ShareableERC721;

  ShareableERC721 = await ethers.getContractFactory("ShareableERC721");
  const contract = ShareableERC721.attach(contract_address)
  const receipt = await contract.addOperator(wallet_address_of_new_operator)
  await receipt.wait()
  console.log("operator added");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });