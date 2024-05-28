// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./AbstractVWBLSettings.sol";

abstract contract AbstractVWBLToken is AbstractVWBLSettings {
    uint256 public counter = 0;
    address private minter = msg.sender;

    mapping(uint256 => bytes32) public tokenIdToUser;
    mapping(bytes32 => bytes32) public userToDocumentId;

    constructor(
        address _gatewayProxy,
        address _accessCheckerContract,
        string memory _signMessage
    ) AbstractVWBLSettings(_gatewayProxy, _accessCheckerContract, _signMessage) {}

    /**
     * @notice Get creator of Diary by tokenId
     * @param tokenId The Identifier of NFT
     */
    function getUser(uint256 tokenId) public view returns (bytes32) {
        return tokenIdToUser[tokenId];
    }

    /**
     * @notice Get minter of NFT. Minter is only one in this business case.
     * @param tokenId The Identifier of NFT
     */
    function getMinter(uint256 tokenId) public view returns (address) {
        return minter;
    }

    /**
     * @notice Get documentId of NFT by minter
     * @param user The hash value of NFT Minter
     */ 
    function getDocumentId(bytes32 user) public view returns (bytes32) {
        return userToDocumentId[user];
    }

    /**
     * @notice Get token Info for each minter
     * @param user The hash value of NFT Diary creator
     */
    function getTokenByUser(bytes32 user) public view returns (uint256[] memory) {
        uint256 resultCount = 0;
        for (uint256 i = 1; i <= counter; i++) {
            if (tokenIdToUser[i] == user) {
                resultCount++;
            }
        }
        uint256[] memory tokens = new uint256[](resultCount);
        uint256 currentCounter = 0;
        for (uint256 i = 1; i <= counter; i++) {
            if (tokenIdToUser[i] == user) {
                tokens[currentCounter++] = i;
            }
        }
        return tokens;
    }
}
