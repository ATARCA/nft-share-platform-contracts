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
  event LProxyCreated(address indexed _sproxy, address indexed _creator, string indexed _symbol);
  event EProxyCreated(address indexed _sproxy, address indexed _creator, string indexed _symbol);
  
  //Create individual BeaconVaults for contracts

  ShareableTokenBeacon immutable s_beacon;
  LikeTokenBeacon immutable l_beacon;
  EndorseTokenBeacon immutable e_beacon;

  constructor(address _shareableTokenBeacon_vLogic, address _likeTokenBeacon_vLogic, address _endorseTokenBeacon_vLogic) {
    //set all beacons up with deployed instances of contracts
    s_beacon = new ShareableTokenBeacon(_shareableTokenBeacon_vLogic, msg.sender);
    console.log("s_beacon logic address", _shareableTokenBeacon_vLogic);
    l_beacon = new LikeTokenBeacon(_likeTokenBeacon_vLogic, msg.sender);
    e_beacon = new EndorseTokenBeacon(_endorseTokenBeacon_vLogic, msg.sender);
    //beacon = new TalkoVaultBeacon(_shareableTokenBeacon_vLogic, _likeTokenBeacon_vLogic, _endorseTokenBeacon_vLogic);
  }

  function SBeaconAddress() public view returns(address) {
    return address(s_beacon);
  }

  function LBeaconAddress() public view returns(address) {
    return address(l_beacon);
  }

  function EBeaconAddress() public view returns(address) {
    return address(e_beacon);
  }

  // create-functions for all beacons, make a new proxy for an existing beacon, initialize it add proxy address ot vault

  function createSProxy(string memory _name, string memory _symbol, uint256 _index, address _owner) external returns(address) { //Todo: access control, consider adding the new owner of proxied contract
    //console.log("Attempting to create a new S Proxy by ", msg.sender);
    //bytes4 _sel = ShareableERC721(address(0)).initialize.selector;
    //console.logBytes4(_sel);
    //address _addr = s_beacon.implementation();
    //console.log("Beacon implementation address ", _addr);
    BeaconProxy proxy = new BeaconProxy(
      address(s_beacon),
      abi.encodeWithSelector(ShareableERC721(address(0)).initialize.selector, _name, _symbol, _owner) //Todo: consider 
    );
    //console.log("Created a new S Proxy by ", msg.sender);
    shareable_t_proxies[_index] = address(proxy);
    //console.log("Deployed proxy at", address(proxy));
    emit SProxyCreated(address(proxy), msg.sender, _symbol);
    return address(proxy);
  }

  function createLProxy(string memory _name, string memory _symbol, uint256 _index, address _owner) external returns(address) {
    BeaconProxy proxy = new BeaconProxy(
      address(l_beacon),
      abi.encodeWithSelector(LikeERC721(address(0)).initialize.selector, _name, _symbol, _owner) //Todo: consider 
    );
    like_t_proxies[_index] = address(proxy);
    //console.log("Deployed proxy at", address(proxy));
    emit LProxyCreated(address(proxy), msg.sender, _symbol);
    return address(proxy);
  }

  function createEProxy(string memory _name, string memory _symbol, uint256 _index, address _owner) external returns(address) {
    BeaconProxy proxy = new BeaconProxy(
      address(e_beacon),
      abi.encodeWithSelector(EndorseERC721(address(0)).initialize.selector, _name, _symbol, _owner) //Todo: consider 
    );
    endorse_t_proxies[_index] = address(proxy);
    //console.log("Deployed proxy at", address(proxy));
    emit EProxyCreated(address(proxy), msg.sender, _symbol);
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