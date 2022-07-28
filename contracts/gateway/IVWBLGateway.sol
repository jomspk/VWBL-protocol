// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the VWBL Gateway as defined in the
 * https://github.com/VWBL-protocol/contracts/ERC721/gateway/VWBLGateway.sol
 */
interface IVWBLGateway {
    /**
     * @notice Get array of documentIds
     */
    function getDocumentIds() external view returns (bytes32[] memory);

    /**
     * @notice Returns whether user has access rights of digital content
     *         This function is called by VWBL Network (Decryption key management network)
     * @param user Decryption key requester 
     * @param documentId The Identifier of digital content and decryption key
     * @return True if user has access rights of digital content
     */
    function hasAccessControl(address user, bytes32 documentId) external view returns (bool);

    /**
     * @notice Grant access control feature and registering access condition of digital content
     * @param documentId The Identifier of digital content and decryption key
     * @param conditionContractAddress The contract address of access condition
     */
    function grantAccessControl(
        bytes32 documentId,
        address conditionContractAddress
    ) external payable;

    /**
     * @notice Withdraw vwbl fee by contract owner
     */
    function withdrawFee() external;

    /**
     * @notice Set new VWBL fee
     * @param newFeeWei new VWBL fee
     */
    function setFeeWei(uint256 newFeeWei) external;

    function feeWei() external view returns (uint256);
}
