// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@oc/token/ERC1155/ERC1155.sol";
import "@oc/access/AccessControl.sol";
import "@oc/security/Pausable.sol";
import "@oc/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@oc/token/ERC1155/extensions/ERC1155Supply.sol";
import "@oc/utils/cryptography/SignatureChecker.sol";
import "@oc/security/ReentrancyGuard.sol";
import "@oc/utils/Strings.sol";

contract SeedOfficialSBT is ERC1155, AccessControl, Pausable, ReentrancyGuard, ERC1155Supply {
    using Strings for uint256;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string public name = "1SeedDao Official NFT";
    string public symbol = "SEED SBT";

    address public validator;
    mapping(bytes32 => bool) private signatureUsed;

    constructor(address _validator) ERC1155("") {
        validator = _validator;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function setValidator(address _validator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        validator = _validator;
    }

    function setURI(string memory newuri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(newuri);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        string memory baseUrl = super.uri(tokenId);
        return string(abi.encodePacked(baseUrl, tokenId.toString(), ".json"));
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function hashMessage(uint256[] memory sbtIds, uint256[] memory amounts) public view returns (bytes32) {
        require(sbtIds.length == amounts.length, "not equal");
        return keccak256(abi.encode(block.chainid, address(this), sbtIds, amounts));
    }

    function mintBatch(uint256[] memory sbtIds, uint256[] memory amounts, bytes memory signature)
        public
        whenNotPaused
        nonReentrant
    {
        bytes32 hash = ECDSA.toEthSignedMessageHash(hashMessage(sbtIds, amounts));
        require(!signatureUsed[hash], "hash used");
        require(SignatureChecker.isValidSignatureNow(validator, hash, signature), "invalid signature");
        for (uint256 i = 0; i < sbtIds.length; i++) {
            _mint(msg.sender, sbtIds[i], amounts[i], "");
        }
        signatureUsed[hash] = true;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) whenNotPaused onlyRole(MINTER_ROLE) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
