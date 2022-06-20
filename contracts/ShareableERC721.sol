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
import "@openzeppelin/contracts/access/AccessControl.sol";

//Todo: make contract pausable
//Todo: add more complex governance tools than ownable

contract ShareableERC721 is ERC721URIStorage, AccessControl {

    // experiment operator
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    //Todo: hardcode addresses that should initially be admins, and whom should be intially the operators of the contract

    string baseURI;

    uint256 internal _currentIndex;
    
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        _currentIndex = uint256(0);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);
        // Jarno
        _setupRole(OPERATOR_ROLE, 0x125e0e620675d46BdB31CF0EFfEe91f4E3127C31);
        // Martin
        _setupRole(OPERATOR_ROLE, 0xBAf811debB67BF5fe7241f383192B97261F8e008);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    //Consider moving event definition to new Interfaces class with Share method
    //What got shared from whom, and from what was it derived from
    //Bob shares Token 1 to Alice which is derived from Token 0
    event Share(address indexed from, address indexed to, uint256 indexed tokenId, uint256 derivedFromTokenId);

    function mint(
        address account
    ) external onlyRole(OPERATOR_ROLE) {
        _mint(account, _currentIndex);
        _currentIndex++;
    }

    function setBaseURI(string memory baseURI_) external onlyRole(OPERATOR_ROLE) {
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

      _mint(to, _currentIndex);

      emit Share(msg.sender, to, _currentIndex, tokenIdToBeShared);
      
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




    //disable transfers 
    //secure minting
    //override functions

    //disable approve (delegated permissions to transfer)
}