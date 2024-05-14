// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

import "../IAccessControlCheckerByNFT.sol";
import "../../AbstractVWBLToken.sol";
import "../IViewPermission.sol";

/**
 * @dev NFT which is added Viewable features that only NFT Owner can view digital content
 */
contract VWBLERC721ERC2981ForMetadata is Ownable, AbstractVWBLToken, ERC721Enumerable, ERC2981, IViewPermission {
    mapping(uint256 => string) private _tokenURIs;
    // tokenId => grantee => bool
    mapping(uint256 => mapping(address => bool)) public hasViewPermission;

    event ViewPermissionGranted(uint256 tokenId, address grantee);
    event ViewPermissionRevoked(uint256 tokenId, address revoker);

    constructor(
        address _gatewayProxy,
        address _accessCheckerContract,
        string memory _signMessage
    ) ERC721("VWBL", "VWBL") AbstractVWBLToken("", _gatewayProxy, _accessCheckerContract, _signMessage) {}

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(bytes(_tokenURIs[tokenId]).length != 0, "ERC721: invalid token ID");
        return _tokenURIs[tokenId];
    }

    /**
     * @notice Mint NFT, grant access feature and register access condition of digital content.
     * @param _metadataURL The URl of nft metadata
     * @param _getKeyURl The URl of VWBL Network(Key management network)
     * @param _feeNumerator Royalty of NFT
     * @param _documentId The Identifier of digital content and decryption key
     */
    function mint(
        string memory _metadataURL,
        string memory _getKeyURl,
        uint96 _feeNumerator,
        bytes32 _documentId
    ) public payable returns (uint256) {
        uint256 tokenId = ++counter;
        TokenInfo memory tokenInfo = TokenInfo(_documentId, msg.sender, _getKeyURl);
        tokenIdToTokenInfo[tokenId] = tokenInfo;
        _mint(msg.sender, tokenId);
        _tokenURIs[tokenId] = _metadataURL;

        if (_feeNumerator > 0) {
            _setTokenRoyalty(tokenId, msg.sender, _feeNumerator);
        }

        // grant access control to nft and pay vwbl fee and register nft data to access control checker contract
        IAccessControlCheckerByNFT(accessCheckerContract).grantAccessControlAndRegisterNFT{value: msg.value}(
            _documentId,
            address(this),
            tokenId
        );

        return tokenId;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Grant view permission to grantee from nft owner
     * @param tokenId The identifier of NFT
     * @param grantee The Address who grantee of view permission right
     */
    function grantViewPermission(uint256 tokenId, address grantee) public returns (uint256) {
        require(msg.sender == ownerOf(tokenId), "msg sender is not nft owner");
        hasViewPermission[tokenId][grantee] = true;
        emit ViewPermissionGranted(tokenId, grantee);
        return tokenId;
    }

    /**
     * @notice Revoke view permission from nft owner
     * @param tokenId The identifier of the NFT
     * @param revoker The address revoking the view permission
     * @return The tokenId of the NFT token
     */
    function revokeViewPermission(uint256 tokenId, address revoker) public returns (uint256) {
        require(msg.sender == ownerOf(tokenId), "msg sender is not nft owner");
        hasViewPermission[tokenId][revoker] = false;
        emit ViewPermissionRevoked(tokenId, revoker);
        return tokenId;
    }

    /**
     * @notice Check view permission to user
     * @param tokenId The Identifier of NFT
     * @param user The address of verification target
     */
    function checkViewPermission(uint256 tokenId, address user) public view returns (bool) {
        return hasViewPermission[tokenId][user];
    }
}
