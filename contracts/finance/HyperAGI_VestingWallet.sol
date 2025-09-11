

// SPDX-License-Identifier: UNLICENSED
/**
 * ONLY FOR TEST PURPOSE, NOT FOR PRODUCTION！！
 * 
 * @title HyperAGI_VestingWallet
 * @dev This is an upgradeable contract for managing token vesting and release schedules
 * Supports linear vesting with configurable release intervals and initial release rates
 * 
 * @dev Deployment Log:
 * ===========================================
 * Contract: HyperAGI_VestingWallet
 * ===========================================
 * 
 * 
 * Configuration:
 * - Vesting Type: Linear vesting with optional initial release
 * - Release Interval: Configurable (in seconds)
 * - Delay Period: Configurable delay before vesting starts
 * - Initial Release Rate: Configurable percentage for first release
 * - Linear Periods: Configurable number of linear vesting periods
 * 
 * Technical Details:
 * - Compiler Version: ^0.8.0
 * - OpenZeppelin Version: ^4.9.0
 * - Contract Type: Upgradeable (Proxy Pattern)
 * - Initialization: Required
 * 
 * Features:
 * - Batch account allocation with vesting schedules
 * - Configurable release intervals and delay periods
 * - Optional initial release rate for immediate partial release
 * - Linear vesting over multiple periods
 * - Date-based release tracking and validation
 * - ETH withdrawal functionality for vested amounts
 * - Event logging for all vesting operations
 * 
 * Security:
 * - OwnableUpgradeable for access control
 * - Role-based access control (MINTER_ROLE)
 * - Input validation on all public functions
 * - Safe math operations with overflow protection
 * - Timestamp validation for release operations
 * 
 * @dev Upgrade History:
 * ===========================================
 * 
 * v1.0 - 2025-09-11:
 * - Initial implementation of vesting wallet functionality
 * - Support for linear vesting with configurable parameters
 * - Batch allocation system for multiple accounts
 * - Date-based release tracking and validation
 * - Role-based access control for allocation operations
 * - Event logging for transparency and tracking
 * 
 */
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "../utils/StrUtil.sol";

import "hardhat/console.sol";

contract HyperAGI_VestingWallet is OwnableUpgradeable, AccessControlUpgradeable {
    using Strings for *;

    receive() external payable {}

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bytes32 public constant RELEASED_AMOUNT = keccak256("RELEASED_AMOUNT");
    bytes32 public constant TOTAL_RELEASED_AMOUNT = keccak256("TOTAL_RELEASED_AMOUNT");
    bytes32 public constant PENDING_RELEASE_AMOUNT = keccak256("PENDING_RELEASE_AMOUNT");

    mapping(bytes32 => uint256) private _amountStorage;

    event eveUpdate(string[] dates, address[] wallets, uint256[] totalReleasedAmounts, uint256[] pendingReleaseAmounts, uint256[] releaseAmounts);

    function initialize(address onlyOwner) public initializer {
        __Ownable_init(onlyOwner);
        _grantRole(MINTER_ROLE, onlyOwner);
        _grantRole(DEFAULT_ADMIN_ROLE, onlyOwner);
    }

    function _getKey(string memory date, address wallet, bytes32 businessName) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(date, wallet, businessName));
    }

    function storeAmount(string memory date, address wallet, bytes32 businessName, uint256 amount) private {
        bytes32 key = _getKey(date, wallet, businessName);
        _amountStorage[key] += amount;
    }

    function _reduceAmount(string memory date, address wallet, bytes32 businessName, uint256 amount) private {
        bytes32 key = _getKey(date, wallet, businessName);
        require(_amountStorage[key] >= amount, "Insufficient amount to reduce");
        _amountStorage[key] -= amount;
    }

    function getAmount(string memory date, address wallet, bytes32 businessName) public view returns (uint256) {
        bytes32 key = _getKey(date, wallet, businessName);
        return _amountStorage[key];
    }

    function getCurrentTimestamp(uint256 timestamp) private pure returns (string memory) {
        uint256 year = (timestamp / 31556926) + 1970;

        // Calculate month
        uint256 month = ((timestamp % 31556926) / 2629743) + 1;

        // Calculate day, completely remove +1 adjustment
        uint256 day = (timestamp % 2629743) / 86400;

        // Add zero-padding logic
        string memory monthStr = month < 10 ? string(abi.encodePacked("0", month.toString())) : month.toString();
        string memory dayStr = day < 10 ? string(abi.encodePacked("0", day.toString())) : day.toString();

        return string(abi.encodePacked(year.toString(), "-", monthStr, "-", dayStr));
    }

    function parseDateToTimestamp(string memory date) private pure returns (uint256) {
        bytes memory dateBytes = bytes(date);
        uint256 year = (uint8(dateBytes[0]) - 48) * 1000 + (uint8(dateBytes[1]) - 48) * 100 + (uint8(dateBytes[2]) - 48) * 10 + (uint8(dateBytes[3]) - 48);
        uint256 month = (uint8(dateBytes[5]) - 48) * 10 + (uint8(dateBytes[6]) - 48);
        uint256 day = (uint8(dateBytes[8]) - 48) * 10 + (uint8(dateBytes[9]) - 48);

        // Basic validation
        require(year >= 1970, "Year must be >= 1970");
        require(month >= 1 && month <= 12, "Month must be between 1 and 12");
        require(day >= 1 && day <= 31, "Day must be between 1 and 31");

        // Calculate timestamp
        uint256 timestamp = (year - 1970) *
            31556926 + // Year
            (month - 1) *
            2629743 + // Month
            (day - 1) *
            86400; // Day

        return timestamp;
    }

    /**
     * @param accounts Array of addresses to receive tokens
     * @param amounts Amount of tokens corresponding to each address
     * @param releaseConfiguration The current array respectively contains: uint256 releaseInterval, uint256 delayVestingNum, uint256 firstRate, uint256 linearVestingNum
     */

    function appendAccountTotalAllocation(address[] memory accounts, uint256[] memory amounts, uint256[] memory releaseConfiguration) public payable onlyRole(MINTER_ROLE) {
        require(accounts.length == amounts.length, "accounts.length != amounts.length");
        require(releaseConfiguration.length == 4, "Invalid release configuration");

        // Calculate the total of amounts
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }

        // Ensure the received amount matches the total of amounts
        require(msg.value == totalAmount, "Received amount does not match the total of amounts");

        // Deconstruct release configuration
        uint256 releaseInterval = releaseConfiguration[0]; // Release interval (seconds)
        uint256 delayVestingNum = releaseConfiguration[1]; // Number of delay vesting periods
        uint256 firstRate = releaseConfiguration[2]; // First release rate
        uint256 linearVestingNum = releaseConfiguration[3]; // Number of linear vesting periods

        uint256 currentTimestamp = block.timestamp;

        uint256 delayTimestamp = currentTimestamp + delayVestingNum * releaseInterval;

        uint256 totalLength = accounts.length * linearVestingNum;

        string[] memory dates = new string[](totalLength);
        address[] memory wallets = new address[](totalLength);
        uint256[] memory totalReleasedAmounts = new uint256[](totalLength);
        uint256[] memory pendingReleaseAmounts = new uint256[](totalLength);
        uint256[] memory releaseAmounts = new uint256[](totalLength);

        uint256 index = 0;

        for (uint256 j = 0; j < linearVestingNum; j++) {
            string memory data = getCurrentTimestamp(delayTimestamp);

            for (uint256 i = 0; i < accounts.length; i++) {
                dates[index] = data;

                wallets[index] = accounts[i];

                address account = accounts[i];

                uint256 amount = amounts[i];

                uint256 firstAmount = 0;
                uint256 avgAmount = 0;

                if (firstRate > 0) {
                    firstAmount = (amount * firstRate) / 100;

                    avgAmount = (amount - firstAmount) / (linearVestingNum - 1);
                } else {
                    avgAmount = amount / linearVestingNum;
                }

                if (j == 0 && firstRate > 0) {
                    storeAmount(data, account, TOTAL_RELEASED_AMOUNT, firstAmount);
                    storeAmount(data, account, PENDING_RELEASE_AMOUNT, firstAmount);
                } else {
                    storeAmount(data, account, TOTAL_RELEASED_AMOUNT, avgAmount);
                    storeAmount(data, account, PENDING_RELEASE_AMOUNT, avgAmount);
                }

                totalReleasedAmounts[index] = getAmount(data, account, TOTAL_RELEASED_AMOUNT);
                pendingReleaseAmounts[index] = getAmount(data, account, PENDING_RELEASE_AMOUNT);
                releaseAmounts[index] = getAmount(data, account, RELEASED_AMOUNT);

                index++;
            }

            delayTimestamp += releaseInterval;
        }

        emit eveUpdate(dates, wallets, totalReleasedAmounts, pendingReleaseAmounts, releaseAmounts);
    }

    function withdraw(string[] memory withdrawDates) public {
        string[] memory dates = new string[](withdrawDates.length);
        address[] memory wallets = new address[](withdrawDates.length);
        uint256[] memory totalReleasedAmounts = new uint256[](withdrawDates.length);
        uint256[] memory pendingReleaseAmounts = new uint256[](withdrawDates.length);
        uint256[] memory releaseAmounts = new uint256[](withdrawDates.length);

        for (uint256 i = 0; i < withdrawDates.length; i++) {
            string memory date = withdrawDates[i];

            uint256 dateTimestamp = parseDateToTimestamp(date);
            require(block.timestamp >= dateTimestamp, "Current timestamp must be greater than or equal to date");

            uint256 pendingReleaseAmount = getAmount(date, msg.sender, PENDING_RELEASE_AMOUNT);

            require(pendingReleaseAmount > 0, "Pending release amount is zero");

            storeAmount(date, msg.sender, RELEASED_AMOUNT, pendingReleaseAmount);
            _reduceAmount(date, msg.sender, PENDING_RELEASE_AMOUNT, pendingReleaseAmount);

            payable(msg.sender).transfer(pendingReleaseAmount);

            dates[i] = date;
            wallets[i] = msg.sender;
            totalReleasedAmounts[i] = getAmount(date, msg.sender, TOTAL_RELEASED_AMOUNT);
            pendingReleaseAmounts[i] = getAmount(date, msg.sender, PENDING_RELEASE_AMOUNT);
            releaseAmounts[i] = getAmount(date, msg.sender, RELEASED_AMOUNT);
        }

        emit eveUpdate(dates, wallets, totalReleasedAmounts, pendingReleaseAmounts, releaseAmounts);
    }

    event ReleaseAmountIncreased(address indexed account, uint256 additionalAmount, uint256 newReleasedAmount);

    function substring(bytes memory str, uint256 startIndex, uint256 endIndex) private pure returns (bytes memory) {
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = str[i];
        }
        return result;
    }
}
