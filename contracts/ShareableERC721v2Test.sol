// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "hardhat/console.sol";

//Todo: make contract pausable
//Todo: add more complex governance tools than ownable

contract ShareableERC721v2Test is ERC721Upgradeable, AccessControlUpgradeable {

    // experiment operator
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    string baseURI;

    uint256 internal _currentIndex;

    function getIndex() public view returns(uint256) {
        return _currentIndex;
    }
    
    function initialize(string memory _name, string memory _symbol, address _owner) external initializer { //Todo: pass owner address
        //console.log('caller of ShareableERC721 was:', msg.sender);
        //console.log('tx origin of ShareableERC721 was:', tx.origin);
        //console.log('new owner of contract', _owner); //Todo: consider making owners of these contracts wallets instead of contracts
        __ERC721_init(_name, _symbol);
        _currentIndex = uint256(0); //Todo: consider moving to somewhere else, clashes with upgradeability
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        _setupRole(OPERATOR_ROLE, _owner);
        //console.log('msg sender', msg.sender);
        //console.log('tx origin', tx.origin);
    }

    /*constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        _currentIndex = uint256(0);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);
    }*/

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
    
    function getIndex2() public view returns(uint256) {
        return _currentIndex*100;
    }

    //disable transfers 
    //secure minting
    //override functions

    //disable approve (delegated permissions to transfer)
}