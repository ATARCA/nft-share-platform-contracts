// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ShareableERC721.sol";
import "./EndorseERC721.sol";
import "./LikeERC721.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

//Handles the collection of contracts and their updates
contract EndorseTokenBeacon is Ownable { //Todo: make initializable, inherit ownership from the deployer
  UpgradeableBeacon immutable endorseTokenBeacon;
  address public endorseTokenBeacon_vLogic;

  constructor(address _endorseTokenBeacon_vLogic, address _owner) {
    endorseTokenBeacon = new UpgradeableBeacon(_endorseTokenBeacon_vLogic);
    endorseTokenBeacon_vLogic = _endorseTokenBeacon_vLogic;
    transferOwnership(_owner);
  }

  function updateEndorseTokenBeacon(address _endorseTokenBeacon_vLogic) public { //Todo: limit rights to initializer
    endorseTokenBeacon.upgradeTo(_endorseTokenBeacon_vLogic);
    endorseTokenBeacon_vLogic = _endorseTokenBeacon_vLogic;
  }

  function implementationEndorsementToken() public view returns(address) {
    return endorseTokenBeacon.implementation();
  }
}