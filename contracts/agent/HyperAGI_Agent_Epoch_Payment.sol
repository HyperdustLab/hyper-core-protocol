// SPDX-License-Identifier: UNLICENSED
/**
 * ONLY FOR TEST PURPOSE, NOT FOR PRODUCTION！！
 * 
 * @title HyperAGI_Agent_Epoch_Payment
 * @dev This is an upgradeable contract for handling agent epoch fee payments
 * After successful payment, it automatically updates the agent's time period
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./HyperAGI_Agent.sol";
import "../HyperAGI_Roles_Cfg.sol";

// Define interface to avoid type conversion issues
interface IHyperAGI_Agent {
    function updateAgentTimePeriod(bytes32 sid, uint256 startTime, uint256 endTime) external;
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
     * @dev Main function for paying epoch fees
     * @param sid unique identifier of the agent
     */
    function payEpochFee(bytes32 sid) public payable {
        require(_agentAddress != address(0), "agent contract not set");
        
        // Fixed payment amount: 0.001 ETH
        uint256 paymentAmount = 0.001 ether;
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
    function getEpochPaymentAmount() public pure returns (uint256) {
        return 0.001 ether;
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
