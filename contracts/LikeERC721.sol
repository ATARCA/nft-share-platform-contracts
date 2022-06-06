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

//Todo: allow adding a group of owners to the contract (check openzeppelin for available governance contracts)

//Todo: if token is burned reset users contribution endorsement related to that contribution
//Todo: make contract pausable

interface project_contributions {
  function tokenExists(uint256 tokenId) external view returns(bool);
  function tokenURI(uint256 tokenId) external view returns (string memory);
  function symbol() external view returns(string memory);
  function ownerOf(uint256 tokenId) external view returns(address);
  function balanceOf(address owner) external view returns(uint256);
}

interface endorsements {
  // has endorsed method required, user has any balance on other contract, means he has endorsed
  function balanceOf(address owner) external view returns(uint256);
  function hasEndorsedContribution(address endorser, uint256 contributionTokenId) external view returns (bool);
}

contract LikeERC721 is ERC721, Ownable {

  // Who endorsed whom, with what token and which contribution
  //Todo: consider removing liker address from event (obfuscate whom has liked, allow people to voice opinion without explicitly telling whom liked what)
  event Like(address indexed liker, address indexed likee, uint256 indexed likeTokenId, uint256 contributionTokenId);

  uint256 internal _currentIndex;
  //Todo: consider upgradeable contracs, non-immutable address
  project_contributions private sc;
  endorsements private pe;

  //Token -> wallet adderss -> boolean
  mapping(uint256 => mapping(address => bool)) private _contributionLikes;

  constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
    _currentIndex = uint256(0);
  }

  function setProjectAddress(project_contributions _project_contributions) public onlyOwner returns (address) {
    sc = _project_contributions;
    return address(sc);
  }

  function getProjectAddress() public view returns (address) {
    return address(sc);
  }

  function setEndorsesAddress(endorsements _endorsements) public onlyOwner returns (address) {
    pe = _endorsements;
    return address(pe);
  }

  function getEndorsesAddress() public view returns (address) {
    return address(pe);
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
    require(sc.tokenExists(contributionTokenId),"Contribution token must exist");

    require(pe.hasEndorsedContribution(msg.sender, contributionTokenId) == false, "Cannot like if already endorsed");

    //Todo: check that wallet haven't already minted an endorsement token for given contribution token
    //Todo: uncertain if this key check works!
    require(_contributionLikes[contributionTokenId][msg.sender] == false, "Contributions cannot be liked twice");
    //msg.sender (address of method caller)
    //Todo: make incrementable token id
    _mint(msg.sender, _currentIndex);
    _contributionLikes[contributionTokenId][msg.sender] = true;

    address _endorsee = sc.ownerOf(contributionTokenId);
    emit Like(msg.sender, _endorsee, _currentIndex, contributionTokenId);
    _currentIndex++; 
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    return sc.tokenURI(tokenId);
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