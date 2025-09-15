// SPDX-License-Identifier: UNLICENSED

/**
 * ONLY FOR TEST PURPOSE, NOT FOR PRODUCTION！！
 *
 * @title HyperAGI_CoreTeam_Vesting
 * @dev This is an upgradeable contract for managing AI agents in the HyperAGI ecosystem
 * Features include core team vesting
 *

 */

pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract HyperAGI_CoreTeam_Vesting is 
    Initializable,
    OwnableUpgradeable,
    AccessControlUpgradeable
{
    // Uses built-in HYPT, no token address needed
    
    // Vesting configuration
    uint256 public vestingPercentage; // 20%
    uint256 public vestingDuration; // 36 months
    uint256 public secondsPerMonth; // 30 days/month
    
    // Vesting status
    uint256 public totalVestingAmount;
    uint256 public vestingStartTime;
    uint256 public totalReleased;
    uint256 public monthlyReleaseAmount; // 每月释放金额
    
    // Beneficiary information (only one can be set)
    address public beneficiary;
    uint256 public beneficiaryShare;
    uint256 public beneficiaryReleased;

    uint256 public totalSupply;
    
    // Role definitions
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    
    // Events
    event BeneficiarySet(address indexed beneficiary, uint256 share);
    event TokensReleased(address indexed beneficiary, uint256 amount);
    event VestingStarted(uint256 startTime, uint256 totalAmount);
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address admin) public initializer {
        __Ownable_init(admin);
        __AccessControl_init();
        
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
        
        // Initialize vesting configuration
        vestingPercentage = 20; // 20%
        vestingDuration = 36; // 36 months
        //secondsPerMonth = 30 * 24 * 60 * 60; // 30 days/month
        secondsPerMonth = 600; // 1 hour/month
    }
    
    // Receive HYPT
    receive() external payable {}
    
    // Set beneficiary (only one can be set)
    function setBeneficiary(address _beneficiary) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_beneficiary != address(0), "Invalid beneficiary");
        require(vestingStartTime == 0, "Vesting already started");
        
        beneficiary = _beneficiary;
        
        emit BeneficiarySet(_beneficiary, 0); // share will be calculated when startVesting
    }
    
    // Start vesting
    function startVesting(uint256 totalAmount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(vestingStartTime == 0, "Vesting already started");
        require(totalAmount > 0, "Amount must be positive");
        require(beneficiary != address(0), "Beneficiary not set");
        
        // Calculate total vesting amount based on percentage
        totalVestingAmount = (totalAmount * vestingPercentage) / 100;
        totalSupply = totalAmount;
        vestingStartTime = block.timestamp;
        
        // Calculate monthly release amount: total vesting amount / vesting duration
        monthlyReleaseAmount = totalVestingAmount / vestingDuration;
        
        // Calculate beneficiary share based on vesting percentage
        beneficiaryShare = totalVestingAmount;
        
        emit VestingStarted(vestingStartTime, totalVestingAmount);
    }
    
    
    // Calculate releasable amount
    function calculateReleasableAmount() public view returns (uint256) {
        if (vestingStartTime == 0 || beneficiary == address(0)) {
            return 0;
        }
        
        uint256 elapsedTime = block.timestamp - vestingStartTime;
        uint256 elapsedMonths = elapsedTime / secondsPerMonth;
        
        // If vesting period is complete, release all remaining amount
        if (elapsedMonths >= vestingDuration) {
            return totalVestingAmount - totalReleased;
        }
        
        // Calculate total releasable amount based on completed months
        // Add 1 to elapsedMonths to ensure immediate release of first period
        uint256 totalReleasable = (elapsedMonths + 1) * monthlyReleaseAmount;
        uint256 releasable = totalReleasable - totalReleased;
        
        // Ensure not exceeding total vesting amount
        if (totalReleased + releasable > totalVestingAmount) {
            releasable = totalVestingAmount - totalReleased;
        }
        
        return releasable;
    }
    
    // Release HYPT
    function release() external {
        require(msg.sender == beneficiary, "Not the beneficiary");
        require(vestingStartTime > 0, "Vesting not started");
        
        uint256 releasableAmount = calculateReleasableAmount();
        require(releasableAmount > 0, "No HYPT to release");
        require(address(this).balance >= releasableAmount, "Insufficient HYPT balance");
        
        beneficiaryReleased += releasableAmount;
        totalReleased += releasableAmount;
        
        // Transfer HYPT directly
        (bool success, ) = payable(beneficiary).call{value: releasableAmount}("");
        require(success, "HYPT transfer failed");
        
        emit TokensReleased(beneficiary, releasableAmount);
    }
    
    // Query methods
    function getVestingInfo() external view returns (
        uint256 _vestingPercentage,
        uint256 _vestingDuration,
        uint256 totalAmount,
        uint256 startTime,
        uint256 released,
        uint256 remaining
    ) {
        _vestingPercentage = vestingPercentage;
        _vestingDuration = vestingDuration;
        totalAmount = totalVestingAmount;
        startTime = vestingStartTime;
        released = totalReleased;
        remaining = totalVestingAmount - totalReleased;
    }
    
    function getBeneficiaryInfo() external view returns (
        address _beneficiary,
        uint256 share,
        uint256 released,
        uint256 releasable,
        uint256 remaining
    ) {
        _beneficiary = beneficiary;
        share = beneficiaryShare;
        released = beneficiaryReleased;
        releasable = calculateReleasableAmount();
        remaining = share - released;
    }
    
    function getCurrentReleasableAmount() external view returns (uint256) {
        return calculateReleasableAmount();
    }
    
    function getHYPTotalSupply() external view returns (uint256) {
        return totalSupply;
    }
    
    function getMonthlyReleaseAmount() external view returns (uint256) {
        return monthlyReleaseAmount;
    }
    
    // Management functions
    function depositHYPT() external payable onlyOwner {
        require(msg.value > 0, "Must send HYPT");
    }
    
    function withdrawHYPT(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "HYPT withdrawal failed");
    }
    
    function grantManagerRole(address manager) external onlyOwner {
        _grantRole(MANAGER_ROLE, manager);
    }
    
    function revokeManagerRole(address manager) external onlyOwner {
        _revokeRole(MANAGER_ROLE, manager);
    }


}
