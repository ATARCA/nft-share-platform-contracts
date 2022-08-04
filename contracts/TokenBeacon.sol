// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenBeacon is Ownable { 
  UpgradeableBeacon immutable tokenBeacon;
  address public tokenBeacon_vLogic;

  constructor(address _tokenBeacon_vLogic, address _owner) {
    tokenBeacon = new UpgradeableBeacon(_tokenBeacon_vLogic);
    tokenBeacon_vLogic = _tokenBeacon_vLogic;
    transferOwnership(_owner);
  }

  function update(address _tokenBeacon_vLogic) public onlyOwner {
    tokenBeacon.upgradeTo(_tokenBeacon_vLogic);
    tokenBeacon_vLogic = _tokenBeacon_vLogic;
  }

  function implementation() public view returns(address) {
    return tokenBeacon.implementation();
  }
}