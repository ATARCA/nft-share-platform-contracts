// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ShareableERC721.sol";
import "./EndorseERC721.sol";
import "./LikeERC721.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

//Handles the collection of contracts and their updates
contract LikeTokenBeacon { //Todo: make initializable, inherit ownership from the deployer
  UpgradeableBeacon immutable likeTokenBeacon;

  address public likeTokenBeacon_vLogic;

  constructor(address _likeTokenBeacon_vLogic) {
    likeTokenBeacon = new UpgradeableBeacon(_likeTokenBeacon_vLogic);
    likeTokenBeacon_vLogic = _likeTokenBeacon_vLogic;
  }

  function updateLikeTokenBeacon(address _likeTokenBeacon_vLogic) public {//Todo: limit rights to initializer
    likeTokenBeacon.upgradeTo(_likeTokenBeacon_vLogic);
    likeTokenBeacon_vLogic = _likeTokenBeacon_vLogic;
  }

  function implementationLikeToken() public view returns(address) {
    return likeTokenBeacon.implementation();
  }
}