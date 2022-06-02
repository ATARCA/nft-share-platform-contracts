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

//Todo: allow endorsing with 'weight' if address has contribution tokens, 2nd version of endorsement contract
//Todo: allow revoking endorsements

//Todo: metadata uri should point to contribution token, or should be the same as the contribution token
//Todo: rename contracts
//Todo: make contract pausable
//Todo: don't allow endorsing if user address has already liked the contribution

interface project_contributions {
  function tokenExists(uint256 tokenId) external view returns(bool);
  function tokenURI(uint256 tokenId) external view returns (string memory);
  function symbol() external view returns(string memory);
  function ownerOf(uint256 tokenId) external view returns(address);
  function balanceOf(address owner) external view returns(uint256);
}

interface likes {
  function balanceOf(address owner) external view returns(uint256);
  function hasLikedContribution(address endorser, uint256 contributionTokenId) external view returns (bool);
  //Todo: check if msg sender has a already liked a specific contribution, a like token for the sender for a specific contribution has been minted
}

contract EndorseERC721 is ERC721, Ownable {

  // Who endorsed whom, with what token and which contribution
  event Endorse(address indexed endorser, address indexed endorsee, uint256 indexed endorsementTokenId, uint256 contributionTokenId);

  uint256 internal _currentIndex;
  //Todo: consider upgradeable contracs, non-immutable address
  project_contributions private sc;
  likes private lc;

  mapping(uint256 => mapping(address => bool)) private _contributionEndorsements;

  constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
    _currentIndex = uint256(0);
  }

  function burn(uint256 tokenId) public {
    _burn(tokenId);
  }

  function setProjectAddress(project_contributions _project_contributions) public onlyOwner returns (address) {
    sc = _project_contributions;
    return address(sc);
  }

  function getProjectAddress() public view returns (address) {
    return address(sc);
  }

  function setLikesAddress(likes _likes) public onlyOwner returns (address) {
    lc = _likes;
    return address(lc);
  }

  function getLikesAddress() public view returns (address) {
    return address(lc);
  }

  function hasEndorsedContribution(address endorser, uint256 contributionTokenId) public view returns (bool) {
    return _contributionEndorsements[contributionTokenId][endorser] == true;
  }

  function mint(
    uint256 contributionTokenId
  ) external {
    //Check that contribution token exists
    require(sc.tokenExists(contributionTokenId),"Contribution token must exist");

    require(lc.hasLikedContribution(msg.sender, contributionTokenId) == false, "Cannot endorse if already liked");

    //Todo: require that minter has a balance of contribution tokens
    require(sc.balanceOf(msg.sender) > 0, "Cannot endorse without any contributions awarded for this account.");

    //Todo: check that wallet haven't already minted an endorsement token for given contribution token
    //Todo: uncertain if this key check works!
    require(_contributionEndorsements[contributionTokenId][msg.sender] == false, "Contributions cannot be endorsed twice");
    //msg.sender (address of method caller)
    //Todo: make incrementable token id
    _mint(msg.sender, _currentIndex);
    _contributionEndorsements[contributionTokenId][msg.sender] = true;

    address _endorsee = sc.ownerOf(contributionTokenId);
    emit Endorse(msg.sender, _endorsee, _currentIndex, contributionTokenId);
    _currentIndex++; 
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