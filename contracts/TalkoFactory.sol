// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ShareableERC721.sol";
import "./EndorseERC721.sol";
import "./LikeERC721.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "./ShareableTokenBeacon.sol";
import "./LikeTokenBeacon.sol";
import "./EndorseTokenBeacon.sol";

import "hardhat/console.sol";

contract TalkoFactory { //Todo: access control

  //Autoincrementable key for proxies ?

  //create mappings for all beacons

  mapping(uint256 => address) private shareable_t_proxies;
  mapping(uint256 => address) private like_t_proxies;
  mapping(uint256 => address) private endorse_t_proxies;

  event SProxyCreated(address indexed _sproxy, address indexed _creator, string indexed _symbol);
  
  //Create individual BeaconVaults for contracts

  ShareableTokenBeacon immutable s_beacon;
  LikeTokenBeacon immutable l_beacon;
  EndorseTokenBeacon immutable e_beacon;

  constructor(address _shareableTokenBeacon_vLogic, address _likeTokenBeacon_vLogic, address _endorseTokenBeacon_vLogic) {
    //set all beacons up with deployed instances of contracts
    s_beacon = new ShareableTokenBeacon(_shareableTokenBeacon_vLogic);
    console.log("s_beacon logic address", _shareableTokenBeacon_vLogic);
    l_beacon = new LikeTokenBeacon(_likeTokenBeacon_vLogic);
    e_beacon = new EndorseTokenBeacon(_endorseTokenBeacon_vLogic);
    //beacon = new TalkoVaultBeacon(_shareableTokenBeacon_vLogic, _likeTokenBeacon_vLogic, _endorseTokenBeacon_vLogic);
  }

  // create-functions for all beacons, make a new proxy for an existing beacon, initialize it add proxy address ot vault

  function createSProxy(string memory _name, string memory _symbol, uint256 _index) external returns(address) { //Todo: access control
    console.log("Attempting to create a new S Proxy by ", msg.sender);
    bytes4 _sel = ShareableERC721(address(0)).initialize.selector;
    console.logBytes4(_sel);
    address _addr = s_beacon.implementation();
    console.log("Beacon implementation address ", _addr);
    BeaconProxy proxy = new BeaconProxy(
      address(s_beacon),
      abi.encodeWithSelector(_sel, _name, _symbol)
    );
    console.log("Created a new S Proxy by ", msg.sender);
    shareable_t_proxies[_index] = address(proxy);
    console.log("Deployed proxy at", address(proxy));
    emit SProxyCreated(address(proxy), msg.sender, _symbol);
    return address(proxy);
  }

  //Refactor other beacons to fulfil IBeacon interface

  // get implementation functions for all beacons

  // get specific proxy by address

  // get address of a beacon

  /*function createShareableBeacon() public returns(address) {
    UpgradeableBeacon ubeacon = new UpgradeableBeacon(address(shareableERC721));
    return address(ubeacon);
  }

  function createShareableProxy(address beacon, string memory _name, string memory _symbol) public returns(address) {
    BeaconProxy proxy = new BeaconProxy(beacon, abi.encode(_name, _symbol));
    return address(proxy);
  }*/
}