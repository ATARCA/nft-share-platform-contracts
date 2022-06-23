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
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

//Todo: rename contracts
//Todo: make contract pausable

interface project_contributions is IERC721Metadata {
  function tokenExists(uint256 tokenId) external view returns(bool);
}

interface contribution_likes is IERC721 {
  function hasLikedContribution(address endorser, uint256 contributionTokenId) external view returns (bool);
  //Todo: check if msg sender has a already liked a specific contribution, a like token for the sender for a specific contribution has been minted
}

contract EndorseERC721 is ERC721, Ownable {

  // Who endorsed whom, with what token and which contribution
  event Endorse(address indexed endorser, address indexed endorsee, uint256 indexed endorsementTokenId, uint256 contributionTokenId);

  uint256 internal _currentIndex;
  //Todo: consider upgradeable contracs, non-immutable address
  project_contributions private contributions_contract;
  contribution_likes private likes_contract;

  mapping(uint256 => mapping(address => bool)) private _contributionEndorsements;

  constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
    _currentIndex = uint256(0);
  }

  function burn(uint256 tokenId) public {
    require(msg.sender == ownerOf(tokenId), "Must be owner of token to be able to burn it");
    _burn(tokenId);
    _contributionEndorsements[tokenId][msg.sender] = false;
  }

  function setProjectAddress(project_contributions _project_contributions) public onlyOwner returns (address) {
    contributions_contract = _project_contributions;
    return address(contributions_contract);
  }

  function getProjectAddress() public view returns (address) {
    return address(contributions_contract);
  }

  function setLikesAddress(contribution_likes _likes) public onlyOwner returns (address) {
    likes_contract = _likes;
    return address(likes_contract);
  }

  function getLikesAddress() public view returns (address) {
    return address(likes_contract);
  }

  function hasEndorsedContribution(address endorser, uint256 contributionTokenId) public view returns (bool) {
    return _contributionEndorsements[contributionTokenId][endorser] == true;
  }

  function mint(
    uint256 contributionTokenId
  ) external {
    //Check that contribution token exists
    require(contributions_contract.tokenExists(contributionTokenId),"Contribution token must exist");

    require(likes_contract.hasLikedContribution(msg.sender, contributionTokenId) == false, "Cannot endorse if already liked");

    //Todo: require that minter has a balance of contribution tokens
    require(contributions_contract.balanceOf(msg.sender) > 0, "Cannot endorse without any contributions awarded for this account.");

    //Todo: check that wallet haven't already minted an endorsement token for given contribution token
    //Todo: uncertain if this key check works!
    require(_contributionEndorsements[contributionTokenId][msg.sender] == false, "Contributions cannot be endorsed twice");
    //msg.sender (address of method caller)
    //Todo: make incrementable token id
    _mint(msg.sender, _currentIndex);
    _contributionEndorsements[contributionTokenId][msg.sender] = true;

    address _endorsee = contributions_contract.ownerOf(contributionTokenId);
    emit Endorse(msg.sender, _endorsee, _currentIndex, contributionTokenId);
    _currentIndex++; 
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    return contributions_contract.tokenURI(tokenId);
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