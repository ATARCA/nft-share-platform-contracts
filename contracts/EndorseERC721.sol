// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

//Todo: rename contracts
//Todo: make contract pausable

interface project_contributions is IERC721Metadata {
  function tokenExists(uint256 tokenId) external view returns(bool);
}

contract EndorseERC721 is ERC721, AccessControl {

  // experiment operator
  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  // Who endorsed whom, with what token and which contribution
  event Endorse(address indexed endorser, address indexed endorsee, uint256 indexed endorsementTokenId, uint256 contributionTokenId);

  uint256 internal _currentIndex;
  //Todo: consider upgradeable contracs, non-immutable address
  project_contributions private contributions_contract;

  mapping(uint256 => mapping(address => bool)) private _contributionEndorsements;

  // Endorse token id => Contribution token Id
  mapping(uint256 => uint256) private _endorsesToContributions;

  constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        _currentIndex = uint256(0);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);
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

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function burn(uint256 tokenId) public {
    require(msg.sender == ownerOf(tokenId), "Must be owner of token to be able to burn it");
    _burn(tokenId);
    _contributionEndorsements[tokenId][msg.sender] = false;
  }

  function setProjectAddress(project_contributions _project_contributions) public onlyRole(OPERATOR_ROLE) returns (address) {
    contributions_contract = _project_contributions;
    return address(contributions_contract);
  }

  function getProjectAddress() public view returns (address) {
    return address(contributions_contract);
  }

  function hasEndorsedContribution(address endorser, uint256 contributionTokenId) public view returns (bool) {
    return _contributionEndorsements[contributionTokenId][endorser] == true;
  }

  function mint(
    uint256 contributionTokenId
  ) external {
    //Check that contribution token exists
    require(contributions_contract.tokenExists(contributionTokenId),"Contribution token must exist");
    require(contributions_contract.balanceOf(msg.sender) > 0, "Cannot endorse without any contributions awarded for this account.");
    require(_contributionEndorsements[contributionTokenId][msg.sender] == false, "Contributions cannot be endorsed twice");

    _mint(msg.sender, _currentIndex);
    _contributionEndorsements[contributionTokenId][msg.sender] = true;
    _endorsesToContributions[_currentIndex] = contributionTokenId;

    address _endorsee = contributions_contract.ownerOf(contributionTokenId);
    emit Endorse(msg.sender, _endorsee, _currentIndex, contributionTokenId);
    _currentIndex++; 
  }

  function tokenURI(uint256 endorseTokenId) public view override returns (string memory) {
    uint256 _contributionTokenId = _endorsesToContributions[endorseTokenId];
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