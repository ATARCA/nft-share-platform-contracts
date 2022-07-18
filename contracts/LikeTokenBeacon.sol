// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ShareableERC721.sol";
import "./EndorseERC721.sol";
import "./LikeERC721.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//Handles the collection of contracts and their updates
contract LikeTokenBeacon is Ownable { //Todo: make initializable, inherit ownership from the deployer
  UpgradeableBeacon immutable likeTokenBeacon;

  address public likeTokenBeacon_vLogic;

  constructor(address _likeTokenBeacon_vLogic, address _owner) {
    likeTokenBeacon = new UpgradeableBeacon(_likeTokenBeacon_vLogic);
    likeTokenBeacon_vLogic = _likeTokenBeacon_vLogic;
    transferOwnership(_owner);
  }

  function update(address _likeTokenBeacon_vLogic) public onlyOwner {//Todo: limit rights to initializer
    likeTokenBeacon.upgradeTo(_likeTokenBeacon_vLogic);
    likeTokenBeacon_vLogic = _likeTokenBeacon_vLogic;
  }

  function implementation() public view returns(address) {
    return likeTokenBeacon.implementation();
  }
}