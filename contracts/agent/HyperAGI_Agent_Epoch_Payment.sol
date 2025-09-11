// SPDX-License-Identifier: UNLICENSED
/**
 * ONLY FOR TEST PURPOSE, NOT FOR PRODUCTION！！
 * 
 * @title HyperAGI_Agent_Epoch_Payment
 * @dev This is an upgradeable contract for handling agent epoch fee payments
 * After successful payment, it automatically updates the agent's time period
 * 
 * @dev Deployment Log:
 * ===========================================
 * Contract: HyperAGI_Agent_Epoch_Payment
 * ===========================================
 * 
 * Initial Deployment:
 * - Date: 2025-01-27
 * - Contract Address: [TO_BE_DEPLOYED]
 * - Network: Conflux Testnet
 * - Deployer: [TO_BE_DEPLOYED]
 * - Transaction Hash: [TO_BE_DEPLOYED]
 * - Block Number: [TO_BE_DEPLOYED]
 * - Gas Used: [TO_BE_DEPLOYED]
 * 
 * Configuration:
 * - Initial Epoch Duration: 384 seconds (6.4 minutes)
 * - Gas Fee Formula: Base / (Difficulty * Factor) * Base
 * - Base Value: 38000
 * - Difficulty: Total agents / Online agents
 * - Factor: Online agents * 300,000,000
 * 
 * Technical Details:
 * - Compiler Version: ^0.8.0
 * - OpenZeppelin Version: ^4.9.0
 * - Contract Type: Upgradeable (Proxy Pattern)
 * - Initialization: Required
 * 
 * Features:
 * - Dynamic gas fee calculation based on agent statistics
 * - Admin role verification system
 * - Input validation and overflow protection
 * - Event logging for payment tracking
 * - ETH withdrawal functionality
 * 
 * Security:
 * - OwnableUpgradeable for access control
 * - Admin role verification via HyperAGI_Roles_Cfg
 * - Input validation on all public functions
 * - Safe math operations with overflow protection
 * 
 * @dev Upgrade History:
 * ===========================================
 * 
 * v1.1 - 2025-09-08:
 * - Implemented dynamic gas fee calculation based on agent statistics
 * - Added formula: Gas Fee = Base / Difficulty / Factor * Base
 * - Base = 38000, Difficulty = Total agents / Online agents, Factor = Online agents * 300,000,000
 * - Added getAgentStatistics() and calculateGasFee() functions
 * - Updated payment functions to use dynamic fee calculation instead of fixed 0.001 ETH
 * - Enhanced precision handling with 1e18 multiplier
 * - Added comprehensive input validation
 * 
 * @dev Deployment Checklist:
 * ===========================================
 * [ ] Deploy contract
 * [ ] Initialize with owner address
 * [ ] Set roles configuration address
 * [ ] Set agent contract address
 * [ ] Verify all functions work correctly
 * [ ] Test payment functionality
 * [ ] Update contract address in deployment log
 * [ ] Update transaction hash and block number
 * [ ] Update gas used information
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./HyperAGI_Agent.sol";
import "../HyperAGI_Roles_Cfg.sol";

// Define interface to avoid type conversion issues
interface IHyperAGI_Agent {
    function updateAgentTimePeriod(bytes32 sid, uint256 startTime, uint256 endTime) external;
    function getAgentAccountLen() external view returns (uint256);
    function getTotalCount() external view returns (uint256);
    function getOnlineCount() external view returns (uint256);
}

contract HyperAGI_Agent_Epoch_Payment is OwnableUpgradeable {
    
    // Time period: 6.4 minutes (384 seconds) - can be modified during upgrade
    uint256 public epochDuration;
    
    // Contract addresses
    address public _rolesCfgAddress;
    address public _agentAddress;
    
    // Payment record event
    event EpochPaymentCompleted(
        bytes32 indexed sid,
        uint256 startTime,
        uint256 endTime,
        uint256 paymentAmount,
        address payer
    );
    
    // Admin role check modifier
    modifier onlyAdmin() {
        require(_rolesCfgAddress != address(0), "roles config not set");
        HyperAGI_Roles_Cfg rolesCfg = HyperAGI_Roles_Cfg(_rolesCfgAddress);
        require(rolesCfg.hasAdminRole(msg.sender) || msg.sender == owner(), "not admin role");
        _;
    }
    
    // Initialize function
    function initialize(address onlyOwner) public initializer {
        __Ownable_init(onlyOwner);
        
        // Initialize time period: 6.4 minutes (384 seconds)
        epochDuration = 384;
    }
    
    // Set roles configuration address
    function setRolesCfgAddress(address rolesCfgAddress) public onlyOwner {
        _rolesCfgAddress = rolesCfgAddress;
    }
    
    // Set Agent contract address
    function setAgentAddress(address agentAddress) public onlyOwner {
        _agentAddress = agentAddress;
    }
    
    
    // Batch set contract addresses
    function setContractAddress(address[] memory contractAddressArray) public onlyOwner {
        require(contractAddressArray.length >= 2, "invalid array length");
        _rolesCfgAddress = contractAddressArray[0];
        _agentAddress = contractAddressArray[1];
    }
    
    /**
     * @dev Get agent statistics (total agents and online agents)
     * @return totalAgents total number of agents
     * @return onlineAgents number of online agents
     */
    function getAgentStatistics() public view returns (uint256 totalAgents, uint256 onlineAgents) {
        if (_agentAddress == address(0)) {
            return (0, 0);
        }
        
        IHyperAGI_Agent agentContract = IHyperAGI_Agent(_agentAddress);
        totalAgents = agentContract.getTotalCount();
        onlineAgents = agentContract.getOnlineCount();
        
        return (totalAgents, onlineAgents);
    }
    
    /**
     * @dev Calculate gas fee based on new formula
     * Formula: Gas Fee = Base / (Difficulty * Factor)
     * Base = 38000 (fixed)
     * Difficulty = Total agents / Online agents
     * Factor = Online agents * 300,000,000
     * @return calculated gas fee
     */
    function calculateGasFee() public view returns (uint256) {
        (uint256 totalAgents, uint256 onlineAgents) = getAgentStatistics();
        
        if (onlineAgents == 0) {
            return 0; // No fee when no agents online
        }
        
        // Ensure minimum agent count
        if (totalAgents < 1) {
            totalAgents = 1;
        }
        
        // Correct formula: Gas Fee = Base / (Difficulty * Factor)
        // Base = 38000 (fixed number)
        // Difficulty = Total agents / Online agents
        // Factor = Online agents * 300,000,000
        
        uint256 base = 38000;
        uint256 difficulty = (totalAgents * 1e18) / onlineAgents; // Use 1e18 precision
        uint256 factor = onlineAgents * 300000000;
        
        // Calculate: Base / (Difficulty * Factor)
        // To avoid precision issues, first calculate Difficulty * Factor, then divide Base by the result
        uint256 difficultyTimesFactor = (difficulty * factor) / 1e18; // Remove precision from difficulty
        uint256 result = (base * 1e18) / difficultyTimesFactor;
        
        // Convert result to wei (1e18 wei = 1 ETH)
        uint256 gasFeeInWei = result*base;
        
        return gasFeeInWei;
    }
    
    /**
     * @dev Main function for paying epoch fees
     * @param sid unique identifier of the agent
     */
    function payEpochFee(bytes32 sid) public payable {
        require(_agentAddress != address(0), "agent contract not set");
        
        // Calculate dynamic payment amount based on new formula
        uint256 paymentAmount = calculateGasFee();
        require(msg.value == paymentAmount, "incorrect payment amount");
        
        // Get current timestamp
        uint256 currentTime = block.timestamp;
        uint256 endTime = currentTime + epochDuration;
        
        // Call HyperAGI_Agent contract's updateAgentTimePeriod function
        IHyperAGI_Agent agentContract = IHyperAGI_Agent(_agentAddress);
        agentContract.updateAgentTimePeriod(sid, currentTime, endTime);
        
        // Emit payment completion event
        emit EpochPaymentCompleted(sid, currentTime, endTime, paymentAmount, msg.sender);
    }
    
    /**
     * @dev Admin pays epoch fee (for special cases)
     * @param sid unique identifier of the agent
     */
    function adminPayEpochFee(bytes32 sid) public onlyAdmin {
        require(_agentAddress != address(0), "agent contract not set");
        
        // Get current timestamp
        uint256 currentTime = block.timestamp;
        uint256 endTime = currentTime + epochDuration;
        
        // Call HyperAGI_Agent contract's updateAgentTimePeriod function
        IHyperAGI_Agent agentContract = IHyperAGI_Agent(_agentAddress);
        agentContract.updateAgentTimePeriod(sid, currentTime, endTime);
        
        // Emit payment completion event (amount 0 indicates admin operation)
        emit EpochPaymentCompleted(sid, currentTime, endTime, 0, msg.sender);
    }
    
    /**
     * @dev Get current epoch payment amount
     * @return current epoch payment amount (in wei)
     */
    function getEpochPaymentAmount() public view returns (uint256) {
        return calculateGasFee();
    }
    
    /**
     * @dev Get epoch duration
     * @return epoch duration (in seconds)
     */
    function getEpochDuration() public view returns (uint256) {
        return epochDuration;
    }
    

    
    /**
     * @dev Set epoch duration (admin only)
     * @param newDuration new duration (in seconds)
     */
    function setEpochDuration(uint256 newDuration) public onlyAdmin {
        require(newDuration > 0, "duration must be greater than 0");
        epochDuration = newDuration;
    }
    
    /**
     * @dev Withdraw ETH from contract (admin only)
     * @param to recipient address
     * @param amount amount to withdraw
     */
    function withdrawETH(address payable to, uint256 amount) public onlyAdmin {
        require(to != address(0), "invalid address");
        require(address(this).balance >= amount, "insufficient balance");
        to.transfer(amount);
    }
    
    /**
     * @dev Withdraw all ETH from contract (admin only)
     * @param to recipient address
     */
    function withdrawAllETH(address payable to) public onlyAdmin {
        require(to != address(0), "invalid address");
        uint256 balance = address(this).balance;
        require(balance > 0, "no balance to withdraw");
        to.transfer(balance);
    }
    
    /**
     * @dev Get contract ETH balance
     * @return contract ETH balance
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    

    
    /**
     * @dev Allow contract to receive ETH
     */
    receive() external payable {}
    
    /**
     * @dev Allow contract to receive ETH (fallback function)
     */
    fallback() external payable {}
}
