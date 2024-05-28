// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import "./IAccessControlCheckerByNFT.sol";
import "../AbstractVWBLToken.sol";

/**
 * @dev NFT which is added Viewable features that only NFT Owner can view digital content
 */
contract VWBLERC721 is Ownable(msg.sender), AbstractVWBLToken, ERC721URIStorage {
    event NFTMinted(address sender, uint256 tokenId);

    constructor(
        address _gatewayProxy,
        address _accessCheckerContract,
        string memory _signMessage
    ) ERC721("VWBL", "VWBL") AbstractVWBLToken(_gatewayProxy, _accessCheckerContract, _signMessage) {}

    /*
     * @notice Mint NFT.
     * @param _tokenId ID of the NFT
     * @param _tokenUri URI of the NFT. It have been already encoded with Base64.
     */ 
    function mintNFT(uint256 _tokenId, string memory _tokenUri) private {
        _safeMint(msg.sender, _tokenId);
        _setTokenURI(_tokenId, _tokenUri);

        emit NFTMinted(msg.sender, _tokenId);
    }

    /*
     * @notice Mint NFT, grant access feature and register access condition of digital content.
     * @param _tokenUri URI of the NFT. It have been already encoded with Base64.
     * @param _documentId The Identifier of digital content and decryption key
     */ 
    // _getKeyUrlのデータがなぜ必要なのかわからなかったから消した
    function mintInitialDiary(string memory _tokenUri, bytes32 _documentId, bytes32 _hashedUser) public payable onlyOwner{
        uint256 _tokenId = ++counter;
        tokenIdToUser[_tokenId] = _hashedUser;
        userToDocumentId[_hashedUser] = _documentId;

        mintNFT(_tokenId, _tokenUri);

        // grant access control to nft and pay vwbl fee and register nft data to access control checker contract
        IAccessControlCheckerByNFT(accessCheckerContract).grantAccessControlAndRegisterNFT{value: msg.value}(
            _documentId,
            address(this),
            _tokenId
        );
    }

    /*
     * @notice Mint NFT, record connection between hash value of user and tokenId.
     * @param _tokenUri URI of the NFT. It have been already encoded with Base64.
     */ 
    function mintAnotherDiary(string memory _tokenUri, bytes32 _hashedUser) public onlyOwner{
        uint256 _tokenId = ++counter;
        tokenIdToUser[_tokenId] = _hashedUser;

        mintNFT(_tokenId, _tokenUri);
    }

}
