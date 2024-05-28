// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IVWBL {
    /**
     * @notice Get VWBL Fee
     */
    function getFee() external view returns (uint256);

    /**
     * @notice Get Gateway Address
     */
    function getGatewayAddress() external view returns (address);

    /**
     * @notice Get a message to be signed of this contract
     */
    function getSignMessage() external view returns (string memory);

    /**
     * @notice Set the message to be signed of this contract
     */
    function setSignMessage(string calldata _signMessage) external;

    /**
     * @notice Get Access-Control-Allow-Origin for VWBL Network to return decryption key
     */
    function getAllowOrigins() external view returns (string memory);

    /**
     * @notice Set Access-Control-Allow-Origin for VWBL Network to return decryption key
     */
    function setAllowOrigins(string memory) external;

    /**
     * @notice Get token Info for each user
     * @param user The hash value of NFT Diary creator
     */
    function getTokenByUser(bytes32 user) external view returns (uint256[] memory);

    /**
     * @notice Get minter of NFT by tokenId
     * @param tokenId The Identifier of NFT
     */
    function getUser(uint256 tokenId) external view returns (bytes32);

    /**
     * @notice Get minter of NFT by tokenId
     * @param tokenId The Identifier of NFT
     */
    function getMinter(uint256 tokenId) external view returns (address);

    /**
     * @notice Get documentId of NFT by minter
     * @param user The hash value of NFT Minter
     */
    function getDocumentId(bytes32 user) external view returns (bytes32);
}

