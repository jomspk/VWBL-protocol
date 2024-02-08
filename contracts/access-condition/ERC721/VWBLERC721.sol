// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import {Base64} from "./libraries/Base64.sol";

import "./IAccessControlCheckerByNFT.sol";
import "../AbstractVWBLToken.sol";

/**
 * @dev NFT which is added Viewable features that only NFT Owner can view digital content
 */
contract VWBLERC721 is Ownable, AbstractVWBLToken, ERC721URIStorage {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    event NFTMinted(address sender, uint256 tokenId);

    constructor(
        address _gatewayProxy,
        address _accessCheckerContract,
        string memory _signMessage
    ) ERC721("VWBL", "VWBL") AbstractVWBLToken(_gatewayProxy, _accessCheckerContract, _signMessage) {}

    // /**
    //  * @notice Mint NFT, grant access feature and register access condition of digital content.
    //  * @param _getKeyURl The URl of VWBL Network(Key management network)
    //  * @param _documentId The Identifier of digital content and decryption key
    //  */
    // function mint(string memory _getKeyURl, bytes32 _documentId) public payable returns (uint256) {
    //     uint256 tokenId = ++counter;
    //     TokenInfo memory tokenInfo = TokenInfo(_documentId, msg.sender, _getKeyURl);
    //     tokenIdToTokenInfo[tokenId] = tokenInfo;
    //     _mint(msg.sender, tokenId);
    //     // grant access control to nft and pay vwbl fee and register nft data to access control checker contract
    //     IAccessControlCheckerByNFT(accessCheckerContract).grantAccessControlAndRegisterNFT{value: msg.value}(
    //         _documentId,
    //         address(this),
    //         tokenId
    //     );

    //     return tokenId;
    // }

    /**
     * @notice Mint NFT, grant access feature and register access condition of digital content.
     * @param _inputJson json data of diary NFT
     * @param _documentId The Identifier of digital content and decryption key
     */
    function makeNFT(string memory _inputJson, bytes32 _documentId) public payable onlyOwner returns (uint256) {
        uint256 newItemId = _tokenIds.current();

        //引数からそのままjsonデータを取得するようにする
        string memory json = Base64.encode(bytes(string(abi.encodePacked(_inputJson))));

        string memory finalTokenUri = string(abi.encodePacked("data:application/json;base64,", json));

        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, finalTokenUri);
        _tokenIds.increment();

        emit NFTMinted(msg.sender, newItemId);
        // grant access control to nft and pay vwbl fee and register nft data to access control checker contract
        IAccessControlCheckerByNFT(accessCheckerContract).grantAccessControlAndRegisterNFT{value: msg.value}(
            _documentId,
            address(this),
            newItemId
        );

        return newItemId;
    }
}
