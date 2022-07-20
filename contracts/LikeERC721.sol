// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "./Helpers.sol";

//Todo: if token is burned reset users contribution endorsement related to that contribution
//Todo: make contract pausable

contract LikeERC721 is ERC721Upgradeable, AccessControlUpgradeable {

  // experiment operator
  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  // Who endorsed whom, with what token and which contribution
  //Todo: consider removing liker address from event (obfucontributions_contractate whom has liked, allow people to voice opinion without explicitly telling whom liked what)
  event Like(address indexed liker, address indexed likee, uint256 indexed likeTokenId, uint256 contributionTokenId);

  uint256 internal _currentIndex;

  function getIndex() public view returns(uint256) {
    return _currentIndex;
  }
  //Todo: consider upgradeable contracs, non-immutable address?
  // Address for proxy contract ?
  IShareableERC721 private contributions_contract;

  //Token -> wallet adderss -> boolean
  mapping(uint256 => mapping(address => bool)) private _contributionLikes;

  // How many like tokens are associated to contribution token
  // Like token id => Contribution token Id
  mapping(uint256 => uint256) private _likesToContributions;

  function initialize(string memory _name, string memory _symbol, address _owner) public initializer {
        __ERC721_init(_name, _symbol);
        _currentIndex = uint256(0); //Todo: consider moving to somewhere else, clashes with upgradeability
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        _setupRole(OPERATOR_ROLE, _owner);
    }

  function addOperator(address newOperater) public onlyRole(DEFAULT_ADMIN_ROLE) {
      _grantRole(OPERATOR_ROLE, newOperater);
  }

  function removeOperator(address operator) public onlyRole(DEFAULT_ADMIN_ROLE) {
      _revokeRole(OPERATOR_ROLE, operator);
  }

  function addAdmin(address newAdmin) public onlyRole(DEFAULT_ADMIN_ROLE) {
      _grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
  }

  function removeAdmin(address admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
      _revokeRole(DEFAULT_ADMIN_ROLE, admin);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, AccessControlUpgradeable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function setProjectAddress(IShareableERC721 _project_contributions) public onlyRole(OPERATOR_ROLE) returns (address) {
    contributions_contract = _project_contributions;
    return address(contributions_contract);
  }

  function getProjectAddress() public view returns (address) {
    return address(contributions_contract);
  }

  function hasLikedContribution(address endorser, uint256 contributionTokenId) public view returns (bool) {
    return _contributionLikes[contributionTokenId][endorser];
  }

  function burn(uint256 tokenId) public {
    require(msg.sender == ownerOf(tokenId), "Must be owner of token to be able to burn it");
    _burn(tokenId);
    _contributionLikes[tokenId][msg.sender] = false;
  }

  function mint(
    uint256 contributionTokenId
  ) external {
    //Check that contribution token exists
    require(contributions_contract.tokenExists(contributionTokenId),"Contribution token must exist");
    require(_contributionLikes[contributionTokenId][msg.sender] == false, "Contributions cannot be liked twice");

    _mint(msg.sender, _currentIndex);
    _contributionLikes[contributionTokenId][msg.sender] = true;
    _likesToContributions[_currentIndex] = contributionTokenId;

    address _endorsee = contributions_contract.ownerOf(contributionTokenId);
    emit Like(msg.sender, _endorsee, _currentIndex, contributionTokenId);
    _currentIndex++; 
  }

  function tokenURI(uint256 likeTokenId) public view override returns (string memory) {
    uint256 _contributionTokenId = _likesToContributions[likeTokenId];

    return contributions_contract.tokenURI(_contributionTokenId);
  }

  function transferFrom(
        address,
        address,
        uint256
    ) public override pure {
        revert('Tokens are not transferrable');
  }

  function safeTransferFrom(
        address,
        address,
        uint256
    ) public override pure {
        revert('Tokens are not transferrable');
  }

  function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
  ) public override pure {
        revert('Tokens are not transferrable');
  }
}