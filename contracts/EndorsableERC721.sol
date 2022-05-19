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

//Todo: add deployed shareable contract address to variable, related to making contract upgradeable
//Todo: allow endorsing with 'weight' if address has contribution tokens, 2nd version of endorsement contract
//Todo: allow revoking endorsements

interface streamr_contributions {
  function tokenExists(uint256 tokenId) external view returns(bool);
  function tokenURI(uint256 tokenId) external view returns (string memory);
  function symbol() external view returns(string memory);
  function ownerOf(uint256 tokenId) external view returns(address);
}

contract EndorsableERC721 is ERC721, Ownable {

  // Who endorsed whom, with what token and which contribution
  event Endorse(address indexed endorser, address indexed endorsee, uint256 indexed endorsementTokenId, uint256 contributionTokenId);

  uint256 internal _currentIndex;
  //Todo: consider upgradeable contracs, non-immutable address
  streamr_contributions immutable sc;

  mapping(uint256 => mapping(address => bool)) private _contributionEndorsements;

  constructor(string memory _name, string memory _symbol, streamr_contributions _streamr_contributions) ERC721(_name, _symbol) {
    sc = _streamr_contributions;
    _currentIndex = uint256(0);
  }

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

  function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override pure {
        revert('Tokens are not transferrable');
  }

  function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override pure {
        revert('Tokens are not transferrable');
  }

  function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
  ) public override pure {
        revert('Tokens are not transferrable');
  }
}