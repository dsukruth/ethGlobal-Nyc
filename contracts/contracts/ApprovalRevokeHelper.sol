// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ApprovalRevokeHelper
 * @dev Batch approval revocation helper for Sentinel security system
 * Deployed on Zircuit testnet for ETHGlobal NYC
 */
contract ApprovalRevokeHelper is Ownable, ReentrancyGuard {
    
    struct ApprovalInfo {
        address token;
        address spender;
        uint256 amount;
        bool isRevoked;
    }

    // Events
    event ApprovalRevoked(address indexed token, address indexed spender, uint256 amount);
    event BatchRevokeInitiated(address indexed user, uint256 approvalCount);
    event EmergencyRevoke(address indexed token, address indexed spender);

    // State variables
    mapping(address => ApprovalInfo[]) public userApprovals;
    mapping(address => mapping(address => mapping(address => bool))) public isRevoked; // user => token => spender => revoked

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Revoke a single ERC20 approval
     * @param _token Token contract address
     * @param _spender Spender address to revoke
     */
    function revokeApproval(address _token, address _spender) external nonReentrant {
        require(_token != address(0), "Invalid token address");
        require(_spender != address(0), "Invalid spender address");
        
        IERC20 token = IERC20(_token);
        uint256 currentAllowance = token.allowance(msg.sender, _spender);
        
        require(currentAllowance > 0, "No approval to revoke");
        require(!isRevoked[msg.sender][_token][_spender], "Already revoked");
        
        // Revoke the approval
        require(token.approve(_spender, 0), "Revoke failed");
        
        isRevoked[msg.sender][_token][_spender] = true;
        
        // Store approval info
        userApprovals[msg.sender].push(ApprovalInfo({
            token: _token,
            spender: _spender,
            amount: currentAllowance,
            isRevoked: true
        }));
        
        emit ApprovalRevoked(_token, _spender, currentAllowance);
    }

    /**
     * @dev Batch revoke multiple ERC20 approvals
     * @param _tokens Array of token addresses
     * @param _spenders Array of spender addresses
     */
    function batchRevokeApprovals(
        address[] calldata _tokens,
        address[] calldata _spenders
    ) external nonReentrant {
        require(_tokens.length == _spenders.length, "Arrays length mismatch");
        require(_tokens.length > 0, "Empty arrays");
        require(_tokens.length <= 50, "Too many approvals"); // Gas limit protection
        
        uint256 revokedCount = 0;
        
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            address spender = _spenders[i];
            
            require(token != address(0), "Invalid token address");
            require(spender != address(0), "Invalid spender address");
            
            IERC20 tokenContract = IERC20(token);
            uint256 currentAllowance = tokenContract.allowance(msg.sender, spender);
            
            if (currentAllowance > 0 && !isRevoked[msg.sender][token][spender]) {
                // Revoke the approval
                if (tokenContract.approve(spender, 0)) {
                    isRevoked[msg.sender][token][spender] = true;
                    
                    // Store approval info
                    userApprovals[msg.sender].push(ApprovalInfo({
                        token: token,
                        spender: spender,
                        amount: currentAllowance,
                        isRevoked: true
                    }));
                    
                    revokedCount++;
                    emit ApprovalRevoked(token, spender, currentAllowance);
                }
            }
        }
        
        emit BatchRevokeInitiated(msg.sender, revokedCount);
    }

    /**
     * @dev Emergency revoke by owner (for compromised wallets)
     * @param _user User address
     * @param _token Token address
     * @param _spender Spender address
     */
    function emergencyRevoke(
        address _user,
        address _token,
        address _spender
    ) external onlyOwner {
        require(_user != address(0), "Invalid user address");
        require(_token != address(0), "Invalid token address");
        require(_spender != address(0), "Invalid spender address");
        
        IERC20 token = IERC20(_token);
        uint256 currentAllowance = token.allowance(_user, _spender);
        
        if (currentAllowance > 0) {
            // Note: This requires the user to have approved this contract
            // In a real implementation, you might need a different approach
            // such as using a proxy or having the user sign a message
            
            isRevoked[_user][_token][_spender] = true;
            
            emit EmergencyRevoke(_token, _spender);
        }
    }

    /**
     * @dev Get all approvals for a user
     * @param _user User address
     */
    function getUserApprovals(address _user) external view returns (ApprovalInfo[] memory) {
        return userApprovals[_user];
    }

    /**
     * @dev Check if an approval is revoked
     * @param _user User address
     * @param _token Token address
     * @param _spender Spender address
     */
    function isApprovalRevoked(
        address _user,
        address _token,
        address _spender
    ) external view returns (bool) {
        return isRevoked[_user][_token][_spender];
    }

    /**
     * @dev Get current allowance for a user
     * @param _user User address
     * @param _token Token address
     * @param _spender Spender address
     */
    function getCurrentAllowance(
        address _user,
        address _token,
        address _spender
    ) external view returns (uint256) {
        IERC20 token = IERC20(_token);
        return token.allowance(_user, _spender);
    }

    /**
     * @dev Get approval count for a user
     * @param _user User address
     */
    function getApprovalCount(address _user) external view returns (uint256) {
        return userApprovals[_user].length;
    }

    /**
     * @dev Check if user has any active approvals
     * @param _user User address
     * @param _tokens Array of token addresses to check
     * @param _spenders Array of spender addresses to check
     */
    function hasActiveApprovals(
        address _user,
        address[] calldata _tokens,
        address[] calldata _spenders
    ) external view returns (bool) {
        require(_tokens.length == _spenders.length, "Arrays length mismatch");
        
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20 token = IERC20(_tokens[i]);
            if (token.allowance(_user, _spenders[i]) > 0) {
                return true;
            }
        }
        
        return false;
    }

    /**
     * @dev Get active approvals summary
     * @param _user User address
     * @param _tokens Array of token addresses to check
     * @param _spenders Array of spender addresses to check
     */
    function getActiveApprovalsSummary(
        address _user,
        address[] calldata _tokens,
        address[] calldata _spenders
    ) external view returns (
        uint256 totalActive,
        uint256 totalValue,
        address[] memory activeTokens,
        address[] memory activeSpenders
    ) {
        require(_tokens.length == _spenders.length, "Arrays length mismatch");
        
        uint256 activeCount = 0;
        uint256 totalVal = 0;
        
        // First pass: count active approvals
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20 token = IERC20(_tokens[i]);
            uint256 allowance = token.allowance(_user, _spenders[i]);
            if (allowance > 0) {
                activeCount++;
                totalVal += allowance;
            }
        }
        
        // Second pass: collect active approvals
        activeTokens = new address[](activeCount);
        activeSpenders = new address[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20 token = IERC20(_tokens[i]);
            uint256 allowance = token.allowance(_user, _spenders[i]);
            if (allowance > 0) {
                activeTokens[index] = _tokens[i];
                activeSpenders[index] = _spenders[i];
                index++;
            }
        }
        
        return (activeCount, totalVal, activeTokens, activeSpenders);
    }
}
