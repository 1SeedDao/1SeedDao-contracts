// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@oc/token/ERC721/ERC721.sol";
import "@oc/access/AccessControl.sol";
import "@oc/security/Pausable.sol";
import "@oc/security/ReentrancyGuard.sol";
import "@oc/utils/cryptography/MerkleProof.sol";
import "@oc/utils/Strings.sol";
import "@oc/utils/Counters.sol";
import "self/error/Error.sol";

contract Profile is ERC721, AccessControl, Pausable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    Counters.Counter private _tokenIdCounter;
    string public baseTokenURI;
    bytes32 public wlMerkleRoot;
    uint256 public publicPrice = 0.05 ether;
    address payable withdrawTo; //withdraw to this address

    constructor(address payable _withdrawTo) ERC721("Profile NFT", "Profile NFT") {
        withdrawTo = _withdrawTo;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        baseTokenURI = "ipfs://bafkreifhxiuc2lgjkbk2pki5wzt4puqfebxfhydkpxmxdbdjdk2saej2pi";
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseTokenURI = _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (ownerOf(tokenId) == address(0)) {
            revert Errors.NFTNotExists();
        }
        return baseTokenURI;
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

    function wlMint(bytes32[] calldata _merkleProof) public whenNotPaused {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_merkleProof, wlMerkleRoot, leaf)) {
            revert Errors.InvalidMerkleProof();
        }
        _mint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function publicMint() public payable whenNotPaused {
        if (msg.value < publicPrice) {
            revert Errors.AmountInsufficient();
        }
        _mint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();
        refundIfOver(publicPrice);
    }

    function refundIfOver(uint256 price_) private nonReentrant {
        if (msg.value > price_) {
            payable(msg.sender).transfer(msg.value - price_);
        }
    }

    function setWlMerkleRoot(bytes32 root) external onlyRole(DEFAULT_ADMIN_ROLE) {
        wlMerkleRoot = root;
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        payable(withdrawTo).transfer(address(this).balance);
    }


    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override whenNotPaused {
        // Do not allow token transfer if `from` is not zero address (i.e., not minting operation)
        if (from != address(0)) {
            revert Errors.NFTTransferNotAllowed();
        }

        // Ensure that the address does not already own a token
        if (balanceOf(to) >= 1) {
            revert Errors.NFTAlreadyExists();
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    receive() external payable virtual {}
}
