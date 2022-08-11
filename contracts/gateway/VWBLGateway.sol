// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../access-condition/IAccessControlChecker.sol";
import "./IVWBLGateway.sol";

/**
 * @dev VWBL Gateway Contract which manage who has access right of digital content.
 */
contract VWBLGateway is IVWBLGateway, Ownable {
    mapping (bytes32 => address) public documentIdToConditionContract;
    bytes32[] public documentIds;

    uint256 public feeWei = 1000000000000000000; // 1MATIC
    uint256 public pendingFee;

    event accessControlAdded(bytes32 documentId, address conditionContract);
    event feeWeiChanged(uint256 oldPercentage, uint256 newPercentage);
    
    constructor(uint256 _feeWei) {
        feeWei = _feeWei;
    }

    /**
     * @notice Get array of documentIds
     */
    function getDocumentIds() public view returns (bytes32[] memory) {
        return documentIds;
    }

    /**
     * @notice Returns True if user has access rights of digital content or digital content creator
     *         This function is called by VWBL Network (Decryption key management network)
     * @param user The address of decryption key requester or decryption key sender to VWBL Network
     * @param documentId The Identifier of digital content and decryption key
     */
    function hasAccessControl(address user, bytes32 documentId) public view returns (bool) {
        address accessConditionContractAddress = documentIdToConditionContract[documentId];
        if (accessConditionContractAddress != address(0)) {
            return IAccessControlChecker(accessConditionContractAddress).checkAccessControl(user, documentId);
        }

        return false;
    }

    /**
     * @notice Grant access control feature and registering access condition of digital content
     * @param documentId The Identifier of digital content and decryption key
     * @param conditionContractAddress The contract address of access condition
     */
    function grantAccessControl(
        bytes32 documentId,
        address conditionContractAddress
    ) public payable {
        require(msg.value <= feeWei, "Fee is too high");
        require(msg.value >= feeWei, "Fee is insufficient");
        require(
            documentIdToConditionContract[documentId] == address(0),
            "documentId is already used"
        );
        
        pendingFee += msg.value;
        documentIdToConditionContract[documentId] = conditionContractAddress;
        documentIds.push(documentId);

        emit accessControlAdded(documentId, conditionContractAddress);
    }

    /**
     * @notice Withdraw vwbl fee by contract owner
     */
    function withdrawFee() public onlyOwner {
        uint256 amount = pendingFee;
        require(amount != 0);
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingFee = 0;
        payable(msg.sender).transfer(amount);
    }

    /**
     * @notice Set new VWBL fee
     * @param newFeeWei new VWBL fee
     */
    function setFeeWei(uint256 newFeeWei) public onlyOwner {
        require(newFeeWei != feeWei);
        uint256 oldFeeWei = feeWei;
        feeWei = newFeeWei;
        emit feeWeiChanged(oldFeeWei, newFeeWei);
    }
}
