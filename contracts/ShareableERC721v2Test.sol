// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

//
//This contract is only for testing proxy beacon upgradeability!
//
contract ShareableERC721v2Test is ERC721Upgradeable, AccessControlUpgradeable {

    // experiment operator
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    string baseURI;

    uint256 internal _currentIndex;

    function getIndex() public view returns(uint256) {
        return _currentIndex;
    }
    
    function initialize(string memory _name, string memory _symbol, address _owner) external initializer {
        __ERC721_init(_name, _symbol);
        _currentIndex = uint256(0);
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        _setupRole(OPERATOR_ROLE, _owner);
    }

    function addOperator(address newOperater) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(OPERATOR_ROLE, newOperater);
    }

    function removeOperator(address operator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(OPERATOR_ROLE, operator);
    }

    function addAdmin(address newAdmin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
    }

    function removeAdmin(address admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(DEFAULT_ADMIN_ROLE, admin);
    }


    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    //Consider moving event definition to new Interfaces class with Share method
    //What got shared from whom, and from what was it derived from
    //Bob shares Token 1 to Alice which is derived from Token 0
    event Share(address indexed from, address indexed to, uint256 indexed tokenId, uint256 derivedFromTokenId);

    // Event for 'original' tokens
    event Mint(address indexed from, address indexed to, uint256 indexed tokenId);

    function mint(
        address account
    ) external onlyRole(OPERATOR_ROLE) {
        _mint(account, _currentIndex);
        emit Mint(msg.sender, account, _currentIndex);
        _currentIndex++;
    }

    function setBaseURI(string memory baseURI_) external onlyRole(OPERATOR_ROLE)  {
        
        address self_ = address(this);
        baseURI = string.concat(baseURI_, StringsUpgradeable.toHexString(uint160(self_), 20),"/");
    }
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function share(address to, uint256 tokenIdToBeShared) external virtual {
      require(to != address(0), "ERC721: mint to the zero address");
      //token has to exist
      require(_exists(tokenIdToBeShared), "ShareableERC721: token to be shared must exist");
      
      require(msg.sender == ownerOf(tokenIdToBeShared), "Method caller must be the owner of token");

      _mint(to, _currentIndex);

      emit Share(msg.sender, to, _currentIndex, tokenIdToBeShared);
      
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

    function tokenExists(uint256 tokenId) external view returns (bool){
        return _exists(tokenId);
    }
    
    function getIndex2() public view returns(uint256) {
        return _currentIndex*100;
    }

    //disable transfers 
    //secure minting
    //override functions

    //disable approve (delegated permissions to transfer)
}