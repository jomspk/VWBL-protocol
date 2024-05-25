// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import {Base64} from "./libraries/Base64.sol";

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
     * @notice Mint NFT, grant access feature and register access condition of digital content.
     * @param _getKeyURl The URl of VWBL Network(Key management network)
     * @param _inputJson json data of diary NFT
     * @param _documentId The Identifier of digital content and decryption key
     */
    // function mintDiary(
    //     string memory _getKeyUrl,
    //     string memory _inputJson,
    //     bytes32 _documentId
    // ) public payable onlyOwner returns (uint256) {
    //     uint256 tokenId = ++counter;

    //     TokenInfo memory tokenInfo = TokenInfo(_documentId, msg.sender, _getKeyUrl);
    //     tokenIdToTokenInfo[tokenId] = tokenInfo;

    //     //引数からそのままjsonデータを取得するようにする
    //     string memory json = Base64.encode(bytes(_inputJson));

    //     string memory finalTokenUri = string(abi.encodePacked("data:application/json;base64,", json));

    //     _safeMint(msg.sender, tokenId);
    //     _setTokenURI(tokenId, finalTokenUri);

    //     emit NFTMinted(msg.sender, tokenId);
    //     // grant access control to nft and pay vwbl fee and register nft data to access control checker contract
    //     IAccessControlCheckerByNFT(accessCheckerContract).grantAccessControlAndRegisterNFT{value: msg.value}(
    //         _documentId,
    //         address(this),
    //         tokenId
    //     );

    //     return tokenId;
    // }

    function mintNFT(uint256 tokenId, string memory _inputJson) private {
        //引数からそのままjsonデータを取得するようにする
        //TODO: encodeした状態のjsonデータを引数として受け取った方がガス代節約できる。
        string memory json = Base64.encode(bytes(_inputJson));

        string memory finalTokenUri = string(abi.encodePacked("data:application/json;base64,", json));

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, finalTokenUri);

        emit NFTMinted(msg.sender, tokenId);
    }

    function mintInitialDiary(string memory _getKeyUrl,string memory _inputJson, bytes32 _documentId) public payable onlyOwner{
        uint256 tokenId = ++counter;
        tokenIdToMinter[tokenId] = msg.sender;
        minterToDocumentId[msg.sender] = _documentId;

        mintNFT(tokenId, _inputJson);

        // grant access control to nft and pay vwbl fee and register nft data to access control checker contract
        IAccessControlCheckerByNFT(accessCheckerContract).grantAccessControlAndRegisterNFT{value: msg.value}(
            _documentId,
            address(this),
            tokenId
        );
    }

    function mintAnotherDiary(string memory _getKeyUrl, string memory _inputJson, bytes32 _documentId) public onlyOwner{
        uint256 tokenId = ++counter;
        tokenIdToMinter[tokenId] = msg.sender;

        mintNFT(tokenId, _inputJson);
    }

}
