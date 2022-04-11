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

//Todo: allow minting to own wallet
//Todo: disable transfers
//Todo: check that token exists before minting
//Todo: 'link' tokens e.g. store reference, fire event for endorsement
//Todo: only one endorsement allowed per wallet per endorsable NFT
//Todo: add deployed shareable contract address to variable

interface streamr_contributions {
  //Todo token exists
  //Todo consider a helper function to check if token exists
  //Todo get metadata url of contribution token 
  function tokenExists(uint256 tokenId) external view returns(bool);
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

//Todo: token should associate to other contracts contribution token
//Todo: add mapping, address -> uint256, other contracts token
//Todo: add mapping, address => mapping(uint256 => uint256)?
//Todo: which contribution token has been endorsed by which endorsement token
//Todo: uint256 <contributionToken> => mapping(address => uint256 <endorsementToken> )

contract EndorsableERC721 is ERC721, Ownable {

  //Endorse from wallet, to wallet ? and which token was endorsed ?
  event Endorse(address indexed from, address indexed to, uint256 indexed tokenId);

  //Todo: check if necessary, already defined on constructor
  uint256 internal contributionContract;
  uint256 internal _currentIndex;
  //Todo: consider upgradeable contracs, non-immutable address
  streamr_contributions immutable sc;

  mapping(uint256 => mapping(address => uint256)) private _contributionEndorsements;

  //Use for fetching metadata url
  mapping(uint256 => uint256) private _endorsementTokenToContributionToken;

  constructor(string memory _name, string memory _symbol, streamr_contributions _streamr_contributions) ERC721(_name, _symbol) {
    sc = _streamr_contributions;
    _currentIndex = uint256(0);
  }

  function setContributionContract(uint256 contractAddress) external onlyOwner {
    contributionContract = contractAddress;
  }

  //Todo: get metadata url from other contract

  function mint(
    uint256 contributionTokenId
  ) external {
    //Check that contribution token exists
    require(sc.tokenExists(contributionTokenId));

    //Todo: check that wallet haven't already minted an endorsement token for given contribution token
    //Todo: uncertain if this key check works!
    require(_contributionEndorsements[contributionTokenId][msg.sender] == 0);
    //msg.sender (address of method caller)
    //Todo: make incrementable token id
    _mint(msg.sender, _currentIndex);
    _currentIndex++; 
  }
}