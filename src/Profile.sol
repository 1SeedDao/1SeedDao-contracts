// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@oc/token/ERC721/ERC721.sol";
import "@oc/access/AccessControl.sol";
import "@oc/security/Pausable.sol";
import "@oc/utils/Strings.sol";
import "@oc/utils/Counters.sol";
import "self/error/Error.sol";

contract Profile is ERC721, AccessControl, Pausable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    Counters.Counter private _tokenIdCounter;
    string public baseTokenURI;
    mapping(bytes32 => bool) private signatureUsed;

    constructor() ERC721("Profile NFT", "Profile NFT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseTokenURI = _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (ownerOf(tokenId) == address(0)) {
            revert Errors.NFTNotExists();
        }
        return string(abi.encodePacked(baseTokenURI, tokenId.toString()));
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mintBatch(address[] memory tos) public whenNotPaused onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < tos.length; i++) {
            _mint(tos[i], _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override
        whenNotPaused
        onlyRole(MINTER_ROLE)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
