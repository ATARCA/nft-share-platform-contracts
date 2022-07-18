// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ShareableERC721.sol";
import "./EndorseERC721.sol";
import "./LikeERC721.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

//Todo: add event, BEACONUPDATED ?

//Handles the collection of contracts and their updates
contract ShareableTokenBeacon is Ownable { //Todo: make initializable or ownable, inherit ownership from the deployer
  UpgradeableBeacon immutable shareableTokenBeacon;

  address public shareableTokenBeacon_vLogic;

  constructor(address _shareableTokenBeacon_vLogic, address _owner) {
    //console.log('STBeacon constructor caller ', msg.sender);
    shareableTokenBeacon = new UpgradeableBeacon(_shareableTokenBeacon_vLogic);
    shareableTokenBeacon_vLogic = _shareableTokenBeacon_vLogic;
    transferOwnership(_owner);
    //console.log('STBeacon owner changed to', _owner);
  }

  function update(address _shareableTokenBeacon_vLogic) public onlyOwner { //Todo: limit rights to initializer
    //console.log('tried to upgrade ',msg.sender);
    shareableTokenBeacon.upgradeTo(_shareableTokenBeacon_vLogic);
    shareableTokenBeacon_vLogic = _shareableTokenBeacon_vLogic;
  }

  function implementation() public view returns(address) {
    return shareableTokenBeacon.implementation();
  }
}