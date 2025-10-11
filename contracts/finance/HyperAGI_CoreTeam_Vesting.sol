// SPDX-License-Identifier: UNLICENSED

/**
 * ONLY FOR TEST PURPOSE, NOT FOR PRODUCTION！！
 *
 * @title HyperAGI_CoreTeam_Vesting_Dev_Test
 * @dev This is an upgradeable contract for managing AI agents in the HyperAGI ecosystem
 * Features include core team vesting
 *

 */

pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract HyperAGI_CoreTeam_Vesting_Dev_Test is Initializable, OwnableUpgradeable, AccessControlUpgradeable {
    // ERC20 token address
    address public token20Address;

    // Vesting configuration
    uint256 public vestingPercentage; // 20%
    uint256 public vestingDuration; // 36 months
    uint256 public secondsPerMonth; // 30 days/month

    // Vesting status
    uint256 public totalVestingAmount;
    uint256 public vestingStartTime;
    uint256 public totalReleased;
    uint256 public monthlyReleaseAmount;

    // Admin information (only one can be set)
    address public admin;
    uint256 public adminShare;
    uint256 public adminReleased;

    uint256 public constant TOTAL_SUPPLY = 210_000_000 ether;

    // Role definitions
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    // Events
    event AdminSet(address indexed admin, uint256 share);
    event TokensReleased(address indexed admin, uint256 amount);
    event VestingStarted(uint256 startTime, uint256 totalAmount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialAdmin, address _token20Address) public initializer {
        __Ownable_init(msg.sender);
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        _grantRole(ADMIN_ROLE, initialAdmin);

        // Initialize vesting configuration
        vestingPercentage = 10; // 10%
        vestingDuration = 36; // 36 months
        //secondsPerMonth = 30 * 24 * 60 * 60; // 30 days/month
        secondsPerMonth = 600; // 1 hour/month
        token20Address = _token20Address;
    }

    // Set admin (only one can be set)
    function setAdmin(address _admin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_admin != address(0), "Invalid admin");
        require(admin == address(0), "Admin already set");
        require(vestingStartTime == 0, "Vesting already started");

        admin = _admin;

        emit AdminSet(_admin, 0); // share will be calculated when startVesting
    }

    // Start vesting
    function startVesting() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(vestingStartTime == 0, "Vesting already started");
        require(admin != address(0), "Admin not set");

        // Calculate total vesting amount based on percentage
        totalVestingAmount = (TOTAL_SUPPLY * vestingPercentage) / 100;
        vestingStartTime = block.timestamp;

        // Calculate monthly release amount: total vesting amount / vesting duration
        monthlyReleaseAmount = totalVestingAmount / vestingDuration;

        // Calculate admin share based on vesting percentage
        adminShare = totalVestingAmount;

        emit VestingStarted(vestingStartTime, totalVestingAmount);
    }

    // Calculate releasable amount
    function calculateReleasableAmount() public view returns (uint256) {
        if (vestingStartTime == 0 || admin == address(0)) {
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

    // Release tokens
    function release() external {
        require(msg.sender == admin, "Not the admin");
        require(vestingStartTime > 0, "Vesting not started");

        uint256 releasableAmount = calculateReleasableAmount();
        require(releasableAmount > 0, "No tokens to release");

        IERC20 token = IERC20(token20Address);
        require(token.balanceOf(address(this)) >= releasableAmount, "Insufficient token balance");

        adminReleased += releasableAmount;
        totalReleased += releasableAmount;

        // Transfer tokens
        require(token.transfer(admin, releasableAmount), "Token transfer failed");

        emit TokensReleased(admin, releasableAmount);
    }

    // Query methods
    function getVestingInfo() external view returns (uint256 _vestingPercentage, uint256 _vestingDuration, uint256 totalAmount, uint256 startTime, uint256 released, uint256 remaining) {
        _vestingPercentage = vestingPercentage;
        _vestingDuration = vestingDuration;
        totalAmount = totalVestingAmount;
        startTime = vestingStartTime;
        released = totalReleased;
        remaining = totalVestingAmount - totalReleased;
    }

    function getAdminInfo() external view returns (address adminAddress, uint256 totalShare, uint256 releasedAmount, uint256 releasableAmount, uint256 remainingAmount) {
        adminAddress = admin;
        totalShare = adminShare;
        releasedAmount = adminReleased;
        releasableAmount = calculateReleasableAmount();
        remainingAmount = adminShare - adminReleased;
    }

    function getCurrentReleasableAmount() external view returns (uint256) {
        return calculateReleasableAmount();
    }

    function getMonthlyReleaseAmount() external view returns (uint256) {
        return monthlyReleaseAmount;
    }

    // Management functions
    function grantManagerRole(address manager) external onlyOwner {
        _grantRole(MANAGER_ROLE, manager);
    }

    function revokeManagerRole(address manager) external onlyOwner {
        _revokeRole(MANAGER_ROLE, manager);
    }
}
