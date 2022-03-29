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

import "hardhat/console.sol";

contract ShareableERC721 is ERC721URIStorage, Ownable {

    string baseURI;

    uint256 internal _currentIndex;
    
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        _currentIndex = uint256(0);
    }

    //Consider moving event definition to new Interfaces class with Share method
    //What got shared from whom, and from what was it derived from
    //Bob shares Token 1 to Alice which is derived from Token 0
    event Share(address indexed from, address indexed to, uint256 indexed tokenId, uint256 derivedFromTokenId);

    function mint(
        address account
    ) external onlyOwner {
        _mint(account, _currentIndex);
        _currentIndex++;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        console.log("base uri set to be", baseURI_);
        baseURI = baseURI_;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    //Todo: rework to take into account latest development of nature of content on reshared tokens
    function share(address to, uint256 tokenIdToBeShared) external virtual {
      require(to != address(0), "ERC721: mint to the zero address");
      //token has to exist
      require(_exists(tokenIdToBeShared), "ShareableERC721: token to be shared must exist");
      
      require(msg.sender == ownerOf(tokenIdToBeShared), "Method caller must be the owner of token");
      
      console.log('Share: index of token', _currentIndex);
      //string memory _tokenURI = tokenURI(_currentIndex);

      //allow appending appending information to tokenURI ?

      _mint(to, _currentIndex);
      //setTokenURI(_currentIndex);
      //_setTokenURI(_currentIndex, tokenURI(_currentIndex));
      //_setTokenURI(_currentIndex, _tokenURI);

      emit Share(msg.sender, to, _currentIndex, tokenIdToBeShared);
      
      _currentIndex++;
      //create new share event, which token was shared by whom to whom
      //read internals if existig token, add information to new token
      //check how and where metadata is saved 
    }

    //Todo: safeShare, similar to safe transfer, check that contract recipient is aware of ERC721 protocol
    //Todo: do we want to enable sharing to contracts

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        revert('Tokens are not transferrable');
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        revert('Tokens are not transferrable');
    }

    //disable transfers 
    //secure minting
    //override functions

    //disable approve (delegated permissions to transfer)
}