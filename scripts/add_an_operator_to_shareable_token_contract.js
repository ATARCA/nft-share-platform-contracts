const tokenURIBase = 'domain/metadata/';
const _ = require("lodash");

//Mumbai Streamr contract address:  0xE4d28C36a1389BF85d5eD8242A2fC3F4e92aDC47
//Mumbai Connecta contract address: 
//Goerli Streamr contract address:  
//Goerli Connecta contract address: 

const contract_address = "0xE4d28C36a1389BF85d5eD8242A2fC3F4e92aDC47"
const wallet_address_of_new_operator = "0xCEd46d1cd7aBBb5098585BD5b199474eAbB69243"

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