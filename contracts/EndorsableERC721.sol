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
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract EndorsableERC721 is ERC721, Ownable {



}