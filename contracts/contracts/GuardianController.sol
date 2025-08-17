// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title GuardianController
 * @dev Guardian-based signer rotation and recovery system for Sentinel
 * Deployed on Zircuit testnet for ETHGlobal NYC
 */
contract GuardianController is Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    struct Guardian {
        address guardian;
        bool isActive;
        uint256 weight;
        uint256 lastActive;
    }

    struct RecoveryRequest {
        address newSigner;
        uint256 timestamp;
        bool executed;
        mapping(address => bool) guardianApprovals;
        uint256 approvalCount;
    }

    // State variables
    mapping(address => Guardian) public guardians;
    address[] public guardianList;
    uint256 public totalGuardianWeight;
    uint256 public requiredWeight;
    uint256 public recoveryDelay = 1 hours;
    
    RecoveryRequest public currentRecovery;
    bool public recoveryInProgress;

    // Events
    event GuardianAdded(address indexed guardian, uint256 weight);
    event GuardianRemoved(address indexed guardian);
    event GuardianWeightUpdated(address indexed guardian, uint256 newWeight);
    event RecoveryInitiated(address indexed newSigner, uint256 timestamp);
    event RecoveryApproved(address indexed guardian, address indexed newSigner);
    event RecoveryExecuted(address indexed oldSigner, address indexed newSigner);
    event RecoveryCancelled();

    // Modifiers
    modifier onlyGuardian() {
        require(guardians[msg.sender].isActive, "Not a guardian");
        _;
    }

    modifier recoveryNotInProgress() {
        require(!recoveryInProgress, "Recovery already in progress");
        _;
    }

    constructor(address _smartAccount) Ownable(_smartAccount) {
        requiredWeight = 2; // Minimum 2 guardians must approve
    }

    /**
     * @dev Add a new guardian
     * @param _guardian Address of the guardian
     * @param _weight Weight of the guardian's vote
     */
    function addGuardian(address _guardian, uint256 _weight) external onlyOwner {
        require(_guardian != address(0), "Invalid guardian address");
        require(!guardians[_guardian].isActive, "Guardian already exists");
        
        guardians[_guardian] = Guardian({
            guardian: _guardian,
            isActive: true,
            weight: _weight,
            lastActive: block.timestamp
        });
        
        guardianList.push(_guardian);
        totalGuardianWeight += _weight;
        
        emit GuardianAdded(_guardian, _weight);
    }

    /**
     * @dev Remove a guardian
     * @param _guardian Address of the guardian to remove
     */
    function removeGuardian(address _guardian) external onlyOwner {
        require(guardians[_guardian].isActive, "Guardian not found");
        
        totalGuardianWeight -= guardians[_guardian].weight;
        guardians[_guardian].isActive = false;
        
        // Remove from guardian list
        for (uint i = 0; i < guardianList.length; i++) {
            if (guardianList[i] == _guardian) {
                guardianList[i] = guardianList[guardianList.length - 1];
                guardianList.pop();
                break;
            }
        }
        
        emit GuardianRemoved(_guardian);
    }

    /**
     * @dev Update guardian weight
     * @param _guardian Address of the guardian
     * @param _newWeight New weight for the guardian
     */
    function updateGuardianWeight(address _guardian, uint256 _newWeight) external onlyOwner {
        require(guardians[_guardian].isActive, "Guardian not found");
        
        totalGuardianWeight = totalGuardianWeight - guardians[_guardian].weight + _newWeight;
        guardians[_guardian].weight = _newWeight;
        
        emit GuardianWeightUpdated(_guardian, _newWeight);
    }

    /**
     * @dev Initiate a recovery process
     * @param _newSigner Address of the new signer
     */
    function initiateRecovery(address _newSigner) external onlyGuardian recoveryNotInProgress {
        require(_newSigner != address(0), "Invalid new signer");
        require(_newSigner != owner(), "New signer cannot be current owner");
        
        recoveryInProgress = true;
        currentRecovery.newSigner = _newSigner;
        currentRecovery.timestamp = block.timestamp;
        currentRecovery.executed = false;
        currentRecovery.approvalCount = 0;
        
        emit RecoveryInitiated(_newSigner, block.timestamp);
    }

    /**
     * @dev Approve a recovery request
     * @param _newSigner Address of the new signer
     */
    function approveRecovery(address _newSigner) external onlyGuardian {
        require(recoveryInProgress, "No recovery in progress");
        require(currentRecovery.newSigner == _newSigner, "New signer mismatch");
        require(!currentRecovery.guardianApprovals[msg.sender], "Already approved");
        require(block.timestamp >= currentRecovery.timestamp + recoveryDelay, "Recovery delay not met");
        
        currentRecovery.guardianApprovals[msg.sender] = true;
        currentRecovery.approvalCount += guardians[msg.sender].weight;
        
        emit RecoveryApproved(msg.sender, _newSigner);
        
        // Check if enough weight has approved
        if (currentRecovery.approvalCount >= requiredWeight) {
            _executeRecovery();
        }
    }

    /**
     * @dev Execute the recovery
     */
    function _executeRecovery() internal {
        require(!currentRecovery.executed, "Recovery already executed");
        
        address oldSigner = owner();
        currentRecovery.executed = true;
        recoveryInProgress = false;
        
        _transferOwnership(currentRecovery.newSigner);
        
        emit RecoveryExecuted(oldSigner, currentRecovery.newSigner);
    }

    /**
     * @dev Cancel recovery request (only by owner)
     */
    function cancelRecovery() external onlyOwner {
        require(recoveryInProgress, "No recovery in progress");
        
        recoveryInProgress = false;
        
        emit RecoveryCancelled();
    }

    /**
     * @dev Get recovery status
     */
    function getRecoveryStatus() external view returns (
        address newSigner,
        uint256 timestamp,
        bool executed,
        uint256 approvalCount,
        bool inProgress
    ) {
        return (
            currentRecovery.newSigner,
            currentRecovery.timestamp,
            currentRecovery.executed,
            currentRecovery.approvalCount,
            recoveryInProgress
        );
    }

    /**
     * @dev Check if guardian has approved current recovery
     */
    function hasGuardianApproved(address _guardian) external view returns (bool) {
        return currentRecovery.guardianApprovals[_guardian];
    }

    /**
     * @dev Get all guardians
     */
    function getAllGuardians() external view returns (address[] memory) {
        return guardianList;
    }

    /**
     * @dev Get guardian info
     */
    function getGuardianInfo(address _guardian) external view returns (
        bool isActive,
        uint256 weight,
        uint256 lastActive
    ) {
        Guardian memory guardian = guardians[_guardian];
        return (guardian.isActive, guardian.weight, guardian.lastActive);
    }
}
