# nft-share-platform-contracts

ATARCA has received funding from the European Union’s Horizon 2020 research and innovation programme.

How to run:

Install libraries:
```
npm ci
```
Compile contracts:
```
npx hardhat compile
```
Test contracts:
```
npx hardhat test
```
Deployment to hardhat network:
```
npx hardhat run scripts/deploy.js
```
Deployment to Ropsten:

Add Alchemy API key to hardhat.config.js

Add Ropsten private key to hardhat.config.js
```
npx hardhat run scripts/deploy.js --network ropsten
```


Todo:
- [x] Skeleton setup for development
- [ ] Specify license before publishing this repo. Contracts set to MIT licence, please change if not suitable.
- [ ] Extend contract deployment to support xdai / networks used in experiments