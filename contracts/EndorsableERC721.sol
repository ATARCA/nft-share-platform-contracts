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

//Todo: disable transfers
//Todo: 'link' tokens e.g. store reference, fire event for endorsement
//Todo: add deployed shareable contract address to variable

//Todo: allow endorsing with 'weight' if address has contribution tokens
//Todo: add check if wallet has any contribution tokens to interface

interface streamr_contributions {
  //Todo get metadata url of contribution token 
  function tokenExists(uint256 tokenId) external view returns(bool);
  function tokenURI(uint256 tokenId) external view returns (string memory);
  function symbol() external view returns(string memory);
  function ownerOf(uint256 tokenId) external view returns(address);
}

//Todo: token should associate to other contracts contribution token
//Todo: add mapping, address -> uint256, other contracts token
//Todo: add mapping, address => mapping(uint256 => uint256)?
//Todo: which contribution token has been endorsed by which endorsement token
//Todo: uint256 <contributionToken> => mapping(address => uint256 <endorsementToken> )

contract EndorsableERC721 is ERC721, Ownable {

  //Endorse from wallet, to wallet ? and which token was endorsed ?
  //Todo: minting an endorsement token should fire an endorse event
  // Who endorsed whom, with what token and which contribution
  //Todo: check who is owner of the contributionTokenId from interfaced contract
  event Endorse(address indexed endorser, address indexed endorsee, uint256 indexed endorsementTokenId, uint256 contributionTokenId);

  uint256 internal _currentIndex;
  //Todo: consider upgradeable contracs, non-immutable address
  streamr_contributions immutable sc;

  mapping(uint256 => mapping(address => bool)) private _contributionEndorsements;

  constructor(string memory _name, string memory _symbol, streamr_contributions _streamr_contributions) ERC721(_name, _symbol) {
    sc = _streamr_contributions;
    _currentIndex = uint256(0);
  }

  //Todo: get metadata url from other contract

  function mint(
    uint256 contributionTokenId
  ) external {
    //Check that contribution token exists
    require(sc.tokenExists(contributionTokenId),"Contribution token must exist");

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
}