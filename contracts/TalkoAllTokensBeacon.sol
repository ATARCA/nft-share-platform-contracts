// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ShareableERC721.sol";
import "./EndorseERC721.sol";
import "./LikeERC721.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

//Handles the collection of contracts and their updates
contract TalkoVaultBeacon { //Todo: make initializable, inherit ownership from the deployer
  UpgradeableBeacon immutable shareableTokenBeacon;
  UpgradeableBeacon immutable likeTokenBeacon;
  UpgradeableBeacon immutable endorseTokenBeacon;

  address public shareableTokenBeacon_vLogic;
  address public likeTokenBeacon_vLogic;
  address public endorseTokenBeacon_vLogic;

  constructor(address _shareableTokenBeacon_vLogic, address _likeTokenBeacon_vLogic, address _endorseTokenBeacon_vLogic) {
    shareableTokenBeacon = new UpgradeableBeacon(_shareableTokenBeacon_vLogic);
    shareableTokenBeacon_vLogic = _shareableTokenBeacon_vLogic;
    likeTokenBeacon = new UpgradeableBeacon(_likeTokenBeacon_vLogic);
    likeTokenBeacon_vLogic = _likeTokenBeacon_vLogic;
    endorseTokenBeacon = new UpgradeableBeacon(_endorseTokenBeacon_vLogic);
    endorseTokenBeacon_vLogic = _endorseTokenBeacon_vLogic;
  }

  function updateShareableToken(address _shareableTokenBeacon_vLogic) public { //Todo: limit rights to initializer
    shareableTokenBeacon.upgradeTo(_shareableTokenBeacon_vLogic);
    shareableTokenBeacon_vLogic = _shareableTokenBeacon_vLogic;
  }

  function updateLikeTokenBeacon(address _likeTokenBeacon_vLogic) public {//Todo: limit rights to initializer
    likeTokenBeacon.upgradeTo(_likeTokenBeacon_vLogic);
    likeTokenBeacon_vLogic = _likeTokenBeacon_vLogic;
  }

  function updateEndorseTokenBeacon(address _endorseTokenBeacon_vLogic) public { //Todo: limit rights to initializer
    endorseTokenBeacon.upgradeTo(_endorseTokenBeacon_vLogic);
    endorseTokenBeacon_vLogic = _endorseTokenBeacon_vLogic;
  }

  function implementationShareableToken() public view returns(address) {
    return shareableTokenBeacon.implementation();
  }

  function implementationLikeToken() public view returns(address) {
    return likeTokenBeacon.implementation();
  }

  function implementationEndorsementToken() public view returns(address) {
    return endorseTokenBeacon.implementation();
  }
}