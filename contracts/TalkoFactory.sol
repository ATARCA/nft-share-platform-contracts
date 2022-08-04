// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ShareableERC721.sol";
import "./EndorseERC721.sol";
import "./LikeERC721.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

import "./TokenBeacon.sol";

contract TalkoFactory { //Todo: access control

  uint256 internal _indexShareableERC721ProxyInstance;
  uint256 internal _indexLikeERC721ProxyInstance;
  uint256 internal _indexEndorseERC721ProxyInstance;

  mapping(bytes32 => bool) private shareable_proxies_names;
  mapping(bytes32 => bool) private likeable_proxies_names;
  mapping(bytes32 => bool) private endorsable_proxies_names;

  event ShareableERC721ProxyCreated(address indexed _sproxy, address indexed _owner, string indexed _name, string _symbol);
  event LikeERC721ProxyCreated(address indexed _lproxy, address indexed _owner, string indexed _name, string _symbol);
  event EndorseERC721ProxyCreated(address indexed _eproxy, address indexed _owner, string indexed _name, string _symbol);

  TokenBeacon immutable s_beacon;
  TokenBeacon immutable l_beacon;
  TokenBeacon immutable e_beacon;

  constructor(address _shareableTokenBeacon_vLogic, address _likeTokenBeacon_vLogic, address _endorseTokenBeacon_vLogic) {
    //set all beacons up with deployed instances of contracts
    s_beacon = new TokenBeacon(_shareableTokenBeacon_vLogic, msg.sender);
    l_beacon = new TokenBeacon(_likeTokenBeacon_vLogic, msg.sender);
    e_beacon = new TokenBeacon(_endorseTokenBeacon_vLogic, msg.sender);
  }

  function getIndexForShareableERC721ProxyInstance() public view returns(uint256) {
    return _indexShareableERC721ProxyInstance;
  }

  function getIndexForLikeERC721ProxyInstance() public view returns(uint256) {
    return _indexLikeERC721ProxyInstance;
  }

  function getIndexForEndorseERC721ProxyInstance() public view returns(uint256) {
    return _indexEndorseERC721ProxyInstance;
  }
 
  function shareableProxyNameExists(string memory _name) public view returns(bool) {
    bytes32 _nameInBytes32 = keccak256(bytes(_name));
    return shareable_proxies_names[_nameInBytes32];
  }

  function setShareableProxiesName(string memory _name) private returns(bool) {
    require(shareableProxyNameExists(_name) == false, "A proxy with given name already exists!");
    bytes32 _nameInBytes32 = keccak256(bytes(_name));
    shareable_proxies_names[_nameInBytes32] = true;
    return true;
  }

  function likeableProxyNameExists(string memory _name) public view returns(bool) {
    bytes32 _nameInBytes32 = keccak256(bytes(_name));
    return likeable_proxies_names[_nameInBytes32];
  }

  function setLikeableProxiesName(string memory _name) private returns(bool) {
    require(likeableProxyNameExists(_name) == false, "A proxy with given name already exists!");
    bytes32 _stringInBytes32 = keccak256(bytes(_name));
    likeable_proxies_names[_stringInBytes32] = true;
    return true;
  }

  function endorsableProxyNameExists(string memory _name) public view returns(bool) {
    bytes32 _stringInBytes32 = keccak256(bytes(_name));
    return endorsable_proxies_names[_stringInBytes32];
  }

  function setEndorsableProxiesName(string memory _name) private returns(bool) {
    require(endorsableProxyNameExists(_name) == false, "A proxy with given name already exists!");
    bytes32 _stringInBytes32 = keccak256(bytes(_name));
    endorsable_proxies_names[_stringInBytes32] = true;
    return true;
  }

  function ShareableERC721BeaconAddress() public view returns(address) {
    return address(s_beacon);
  }

  function LikeERC721BeaconAddress() public view returns(address) {
    return address(l_beacon);
  }

  function EndorseERC721BeaconAddress() public view returns(address) {
    return address(e_beacon);
  }

  function createShareableERC721Proxy(string memory _name, string memory _symbol, address _owner) external returns(address) {
    setShareableProxiesName(_name);

    BeaconProxy proxy = new BeaconProxy(
      address(s_beacon),
      abi.encodeWithSelector(ShareableERC721(address(0)).initialize.selector, _name, _symbol, _owner) 
    );
    emit ShareableERC721ProxyCreated(address(proxy), _owner, _name, _symbol);
    _indexShareableERC721ProxyInstance++;
    return address(proxy);
  }

  function createLikeERC721Proxy(string memory _name, string memory _symbol, address _owner) external returns(address) {
    setLikeableProxiesName(_name);
    BeaconProxy proxy = new BeaconProxy(
      address(l_beacon),
      abi.encodeWithSelector(LikeERC721(address(0)).initialize.selector, _name, _symbol, _owner) 
    );
    emit LikeERC721ProxyCreated(address(proxy), _owner,_name, _symbol);
    _indexLikeERC721ProxyInstance++;
    return address(proxy);
  }

  function createEndorseERC721Proxy(string memory _name, string memory _symbol, address _owner) external returns(address) {
    setEndorsableProxiesName(_name);
    BeaconProxy proxy = new BeaconProxy(
      address(e_beacon),
      abi.encodeWithSelector(EndorseERC721(address(0)).initialize.selector, _name, _symbol, _owner) 
    );
    emit EndorseERC721ProxyCreated(address(proxy), _owner, _name, _symbol);
    _indexEndorseERC721ProxyInstance++;
    return address(proxy);
  }
}