// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IERC5023.sol";
import "hardhat/console.sol";

//Todo: make contract pausable
//Todo: add more complex governance tools than ownable

contract ShareableERC721 is ERC721URIStorage, Ownable, IERC5023 {

    string baseURI;

    uint256 internal _currentIndex;
    
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        _currentIndex = uint256(0);
    }

    function mint(
        address account
    ) external onlyOwner {
        _mint(account, _currentIndex);
        _currentIndex++;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        
        address self_ = address(this);
        baseURI = string.concat(baseURI_, Strings.toHexString(uint160(self_), 20),"/");
    }
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    //Todo: rework to take into account latest development of nature of content on reshared tokens
    function share(address to, uint256 tokenIdToBeShared) public {
      require(to != address(0), "ERC721: mint to the zero address");
      require(_exists(tokenIdToBeShared), "ShareableERC721: token to be shared must exist");
      require(msg.sender == ownerOf(tokenIdToBeShared), "Method caller must be the owner of token");

      console.log("Share method (2 params): caller", msg.sender);
      console.log("Share method (2 params): to address", to);
      console.log("Share method (2 params): token to be shared", tokenIdToBeShared);
      // preserve msg.sender
      (bool success, ) = address(this).delegatecall(abi.encodeWithSignature("share(address,uint256,uint256)", to, tokenIdToBeShared, _currentIndex));
      if (!success) {
        revert("Failed to share");
      }
    }

    function share(address to, uint256 tokenIdToBeShared, uint256 newTokenId) public {
      console.log("Share method (3 params): caller", msg.sender);
      require(to != address(0), "ERC721: mint to the zero address");
      //token has to exist
      require(_exists(tokenIdToBeShared), "ShareableERC721: token to be shared must exist");
      require(msg.sender == ownerOf(tokenIdToBeShared), "Method caller must be the owner of token");
      _mint(to, newTokenId);
      emit Share(msg.sender, to, newTokenId, tokenIdToBeShared);
      _currentIndex++;
    }

    //Todo: safeShare, similar to safe transfer, check that contract recipient is aware of ERC721 protocol
    //Todo: do we want to enable sharing to contracts

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

    function tokenExists(uint256 tokenId) external view returns (bool){
        return _exists(tokenId);
    }

    //disable approve (delegated permissions to transfer)
}