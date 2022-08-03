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

  //keccak256 bytes32 hash map of strings
  mapping(bytes32 => bytes32) private shareable_proxies_names_and_symbols;
  mapping(bytes32 => bytes32) private likeable_proxies_names_and_symbols;
  mapping(bytes32 => bytes32) private endorsable_proxies_names_and_symbols;

  //Autoincrementable key for proxies ?
  mapping(uint256 => address) private shareable_t_proxies;
  mapping(uint256 => address) private like_t_proxies;
  mapping(uint256 => address) private endorse_t_proxies;

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

  //name and symbol exist 
  function shareableProxyNameAndSymbolExists(string memory _name, string memory _symbol) public view returns(bool) {
    //compare name to stored hash
    bytes32 _nameInBytes32 = keccak256(bytes(_name));
    bytes32 _symbolInBytes32 = keccak256(bytes(_symbol));
    return shareable_proxies_names_and_symbols[_nameInBytes32] == _symbolInBytes32;
  }

  function setShareableProxiesNameAndSymbols(string memory _name, string memory _symbol) private returns(bool) {
    require(shareableProxyNameAndSymbolExists(_name,_symbol) == false, "A proxy with given name and symbol already exists!");
    bytes32 _nameInBytes32 = keccak256(bytes(_name));
    bytes32 _symbolInBytes32 = keccak256(bytes(_symbol));
    shareable_proxies_names_and_symbols[_nameInBytes32] = _symbolInBytes32;
    return true;
  }

  function likeableProxyNameAndSymbolExists(string memory _name, string memory _symbol) public view returns(bool) {
    //compare name to stored hash
    bytes32 _nameInBytes32 = keccak256(bytes(_name));
    bytes32 _symbolInBytes32 = keccak256(bytes(_symbol));
    return likeable_proxies_names_and_symbols[_nameInBytes32] == _symbolInBytes32;
  }

  function setLikeableProxiesNameAndSymbols(string memory _name, string memory _symbol) private returns(bool) {
    require(likeableProxyNameAndSymbolExists(_name,_symbol) == false, "A proxy with given name and symbol already exists!");
    bytes32 _stringInBytes32 = keccak256(bytes(_name));
    bytes32 _symbolInBytes32 = keccak256(bytes(_symbol));
    likeable_proxies_names_and_symbols[_stringInBytes32] = _symbolInBytes32;
    return true;
  }

  function endorsableProxyNameAndSymbolExists(string memory _name, string memory _symbol) public view returns(bool) {
    //compare name to stored hash
    bytes32 _stringInBytes32 = keccak256(bytes(_name));
    bytes32 _symbolInBytes32 = keccak256(bytes(_symbol));
    return endorsable_proxies_names_and_symbols[_stringInBytes32] == _symbolInBytes32;
  }

  function setEndorsbleProxiesNameAndSymbols(string memory _name, string memory _symbol) private returns(bool) {
    require(endorsableProxyNameAndSymbolExists(_name,_symbol) == false, "A proxy with given name and symbol already exists!");
    bytes32 _stringInBytes32 = keccak256(bytes(_name));
    bytes32 _symbolInBytes32 = keccak256(bytes(_symbol));
    endorsable_proxies_names_and_symbols[_stringInBytes32] = _symbolInBytes32;
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
    setShareableProxiesNameAndSymbols(_name,_symbol);

    BeaconProxy proxy = new BeaconProxy(
      address(s_beacon),
      abi.encodeWithSelector(ShareableERC721(address(0)).initialize.selector, _name, _symbol, _owner) 
    );
    shareable_t_proxies[_indexShareableERC721ProxyInstance] = address(proxy);
    emit ShareableERC721ProxyCreated(address(proxy), _owner, _name, _symbol);
    _indexShareableERC721ProxyInstance++;
    return address(proxy);
  }

  function createLikeERC721Proxy(string memory _name, string memory _symbol, address _owner) external returns(address) {
    setLikeableProxiesNameAndSymbols(_name, _symbol);
    BeaconProxy proxy = new BeaconProxy(
      address(l_beacon),
      abi.encodeWithSelector(LikeERC721(address(0)).initialize.selector, _name, _symbol, _owner) 
    );
    like_t_proxies[_indexLikeERC721ProxyInstance] = address(proxy);
    emit LikeERC721ProxyCreated(address(proxy), _owner,_name, _symbol);
    _indexLikeERC721ProxyInstance++;
    return address(proxy);
  }

  function createEndorseERC721Proxy(string memory _name, string memory _symbol, address _owner) external returns(address) {
    setEndorsbleProxiesNameAndSymbols(_name, _symbol);
    BeaconProxy proxy = new BeaconProxy(
      address(e_beacon),
      abi.encodeWithSelector(EndorseERC721(address(0)).initialize.selector, _name, _symbol, _owner) 
    );
    endorse_t_proxies[_indexEndorseERC721ProxyInstance] = address(proxy);
    emit EndorseERC721ProxyCreated(address(proxy), _owner, _name, _symbol);
    _indexEndorseERC721ProxyInstance++;
    return address(proxy);
  }
}