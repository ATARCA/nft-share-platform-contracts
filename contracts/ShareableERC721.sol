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

//Todo: instead of transferring a token from a wallet to wallet, remint it to new wallet and keep 'original' in wallet
//Todo: only allow sharing if the requester has the nft
//Todo: only allow minting by a specific party
//Todo: secure minting
//Todo: secure transfer
//Todo: override inherited mint, transfer contracts

contract ShareableERC721 is ERC721URIStorage, Ownable {

    string baseURI;
    
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    //Consider moving event definition to new Interfaces class with Share method
    event Share(address indexed from, address indexed to, uint256 indexed tokenId);

    function mint(
        address account,
        uint256 tokenId
    ) external onlyOwner {
        _mint(account, tokenId);
    }

    function setTokenURI(
        uint256 tokenId, 
        string memory tokenURI
    ) external {
        _setTokenURI(tokenId, tokenURI);
    }

    function setBaseURI(string memory baseURI_) external {
        baseURI = baseURI_;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function share(address to, uint256 tokenIdToBeShared, uint256 newTokenId) external virtual {
      require(to != address(0), "ERC721: mint to the zero address");
      //token has to exist
      require(_exists(tokenIdToBeShared), "ShareableERC721: token to be shared must exist");
      require(!_exists(newTokenId), "token with given id already exists");
      
      require(msg.sender == ownerOf(tokenIdToBeShared), "Method caller must be the owner of token");

      string memory _tokenURI = tokenURI(tokenIdToBeShared);

      //allow appending appending information to tokenURI ?

      _mint(to, newTokenId);
      _setTokenURI(newTokenId, _tokenURI);

      emit Share(msg.sender, to, newTokenId);

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