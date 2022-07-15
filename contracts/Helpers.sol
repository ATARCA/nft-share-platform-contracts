
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

interface IShareableERC721 is IERC721MetadataUpgradeable {
  function tokenExists(uint256 tokenId) external view returns(bool);
}