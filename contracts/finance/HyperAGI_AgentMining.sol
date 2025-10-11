// SPDX-License-Identifier: UNLICENSED

// @title HyperAGI_AgentMining
// @dev This is an upgradeable contract for managing Agent Mining rewards in the HyperAGI ecosystem
// Features include Agent Mining rewards distribution, migration from old HyperAGI_AgentWallet contract, and data verification
// @dev Upgrade History:
// - 2025-10-11: Added migration from old HyperAGI_AgentWallet contract
// - 2025-10-11: Added data verification functions

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts/utils/math/Math.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "../utils/StrUtil.sol";

// Interface for reading data from old HyperAGI_AgentWallet contract
interface IHyperAGI_AgentWallet {
    function _GPUMiningTotalAward() external view returns (uint256);

    function _epochAward() external view returns (uint256);

    function _lastGPUMiningMintTime() external view returns (uint256);

    function _GPUMiningCurrAward() external view returns (uint256);

    function _TGE_timestamp() external view returns (uint256);

    // Migration getter functions
    function getMigrationData() external view returns (uint256 GPUMiningCurrMiningRatio, uint256 GPUMiningCurrYearTotalSupply, uint256 GPUMiningCurrYearTotalAward, uint256 GPUMiningReleaseInterval, uint256 GPUMiningRateInterval, uint256 GPUMiningAllowReleaseTime, uint256 lastGPUMiningRateTime);
}

contract HyperAGI_AgentMining is OwnableUpgradeable, AccessControlUpgradeable {
    using Strings for *;
    using StrUtil for *;

    using Math for uint256;
    uint256 public _AgentMiningTotalAward;

    uint256 private _AgentMiningCurrMiningRatio;

    uint256 constant FACTOR = 10 ** 18 * 100;

    uint256 private _AgentMiningCurrYearTotalSupply;

    uint256 public _epochAward;

    uint256 private _AgentMiningCurrYearTotalAward;

    uint256 private _AgentMiningReleaseInterval;

    uint256 private _AgentMiningRateInterval;

    uint256 private _AgentMiningAllowReleaseTime;

    uint256 private _lastAgentMiningRateTime;

    uint256 public _lastAgentMiningMintTime;

    uint256 public _AgentMiningCurrAward;

    uint256 public _TGE_timestamp;

    // Migration related variables
    bool private _migrationCompleted;
    address private _oldContractAddress;

    // Migration event
    event eveMigrationCompleted(address oldContract, uint256 timestamp);

    receive() external payable {}

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @dev Standard initialize function without migration
     */
    function initialize(address onlyOwner, uint256 AgentMiningReleaseInterval) public initializer {
        __Ownable_init(onlyOwner);
        _grantRole(DEFAULT_ADMIN_ROLE, onlyOwner);

        _AgentMiningTotalAward = (210000000 ether * 40) / 100;
        _AgentMiningCurrMiningRatio = 10 * 10 ** 18;
        _AgentMiningCurrYearTotalSupply = Math.mulDiv(_AgentMiningTotalAward, _AgentMiningCurrMiningRatio, FACTOR);

        _epochAward = _AgentMiningCurrYearTotalSupply / 365 / 225;

        _AgentMiningReleaseInterval = AgentMiningReleaseInterval;
        _AgentMiningRateInterval = 4 * AgentMiningReleaseInterval;
    }

    function getAgentMiningCurrAllowMintTotalNum() public view returns (uint256, uint256, uint256) {
        require(_AgentMiningAllowReleaseTime > 0, "The commencement of the release of Agent mining has not yet commenced");

        uint256 AgentMiningCurrMiningRatio = _AgentMiningCurrMiningRatio;
        uint256 AgentMiningCurrYearTotalAward = _AgentMiningCurrYearTotalAward;

        uint256 AgentMiningCurrYearTotalSupply = _AgentMiningCurrYearTotalSupply;

        uint256 epochAward = _epochAward;

        if (block.timestamp >= _lastAgentMiningRateTime + _AgentMiningRateInterval) {
            AgentMiningCurrMiningRatio = Math.mulDiv(AgentMiningCurrMiningRatio, FACTOR, 2 * FACTOR);

            require(AgentMiningCurrMiningRatio > 0, "currMiningRatio is 0");
        }

        if (block.timestamp >= _AgentMiningAllowReleaseTime + _AgentMiningReleaseInterval) {
            AgentMiningCurrYearTotalAward = 0;

            AgentMiningCurrYearTotalSupply = Math.mulDiv(_AgentMiningTotalAward - _AgentMiningCurrAward, AgentMiningCurrMiningRatio, FACTOR);

            epochAward = AgentMiningCurrYearTotalSupply / 365 / 225;
        }

        if (block.timestamp >= _AgentMiningAllowReleaseTime) {
            if (block.timestamp - _lastAgentMiningMintTime >= 384) {
                return (AgentMiningCurrYearTotalSupply - AgentMiningCurrYearTotalAward, AgentMiningCurrYearTotalSupply, epochAward);
            } else {
                return (0, AgentMiningCurrYearTotalSupply, epochAward);
            }
        } else {
            return (0, 0, epochAward);
        }
    }

    function mint(address payable account, uint256 mintNum) public onlyRole(MINTER_ROLE) {
        require(_TGE_timestamp > 0, "TGE_timestamp is not started");

        if (block.timestamp >= _lastAgentMiningRateTime + _AgentMiningRateInterval) {
            _AgentMiningCurrMiningRatio = _AgentMiningCurrMiningRatio / 2;
            require(_AgentMiningCurrMiningRatio > 0, "currMiningRatio is 0");

            _lastAgentMiningRateTime += _AgentMiningRateInterval;
        }

        if (block.timestamp >= _AgentMiningAllowReleaseTime + _AgentMiningReleaseInterval) {
            _AgentMiningCurrYearTotalAward = 0;

            _AgentMiningAllowReleaseTime += _AgentMiningReleaseInterval;

            _AgentMiningCurrYearTotalSupply = Math.mulDiv(_AgentMiningTotalAward - _AgentMiningCurrAward, _AgentMiningCurrMiningRatio, FACTOR);

            _epochAward = _AgentMiningCurrYearTotalSupply / 365 / 225;
        }
        require(_AgentMiningCurrYearTotalSupply - _AgentMiningCurrYearTotalAward - mintNum >= 0, "currYearTotalSupply is not enough");

        require(_AgentMiningTotalAward - _AgentMiningCurrAward - mintNum >= 0, "AgentMiningTotalAward is not enough");

        require(_epochAward >= mintNum, string(abi.encodePacked("epochAward (", _epochAward.toString(), ") is not enough for mintNum (", mintNum.toString(), ")")));

        _AgentMiningCurrYearTotalAward += mintNum;
        _AgentMiningCurrAward += mintNum;

        _lastAgentMiningMintTime = block.timestamp;

        transferETH(account, mintNum);
    }

    function startTGE(uint256 TGE_timestamp) public onlyOwner {
        require(_TGE_timestamp == 0, "TGE_timestamp is started");

        _TGE_timestamp = TGE_timestamp;

        _AgentMiningAllowReleaseTime = TGE_timestamp;
        _lastAgentMiningMintTime = TGE_timestamp;
    }

    function transferETH(address payable recipient, uint256 amount) private {
        require(address(this).balance >= amount, "Insufficient balance in contract");
        recipient.transfer(amount);
    }

    function recalculateAgentMiningTotalAward() public onlyOwner {
        _AgentMiningTotalAward = (210000000 ether * 20) / 100;
        _AgentMiningCurrMiningRatio = 10 * 10 ** 18;
        _AgentMiningCurrYearTotalSupply = Math.mulDiv(_AgentMiningTotalAward, _AgentMiningCurrMiningRatio, FACTOR);

        _epochAward = _AgentMiningCurrYearTotalSupply / 365 / 225;

        _AgentMiningRateInterval = 4 * _AgentMiningReleaseInterval;
    }

    /**
     * @dev Migrate data from old contract (can be called after standard initialize if needed)
     * @param oldContractAddress Address of the old HyperAGI_AgentWallet contract
     */
    function migrateFromOldContract(address oldContractAddress) public onlyOwner {
        require(!_migrationCompleted, "Migration already completed");
        require(oldContractAddress != address(0), "Invalid old contract address");

        _oldContractAddress = oldContractAddress;
        _migrateFromOldContract();
        _migrationCompleted = true;
    }

    /**
     * @dev Internal migration logic
     */
    function _migrateFromOldContract() private {
        IHyperAGI_AgentWallet oldContract = IHyperAGI_AgentWallet(_oldContractAddress);

        // Migrate public variables
        _AgentMiningTotalAward = oldContract._GPUMiningTotalAward();
        _epochAward = oldContract._epochAward();
        _lastAgentMiningMintTime = oldContract._lastGPUMiningMintTime();
        _AgentMiningCurrAward = oldContract._GPUMiningCurrAward();
        _TGE_timestamp = oldContract._TGE_timestamp();

        // Migrate private variables using getter function
        (uint256 currMiningRatio, uint256 currYearTotalSupply, uint256 currYearTotalAward, uint256 releaseInterval, uint256 rateInterval, uint256 allowReleaseTime, uint256 lastRateTime) = oldContract.getMigrationData();

        _AgentMiningCurrMiningRatio = currMiningRatio;
        _AgentMiningCurrYearTotalSupply = currYearTotalSupply;
        _AgentMiningCurrYearTotalAward = currYearTotalAward;

        // Only migrate these if not already set
        if (_AgentMiningReleaseInterval == 0) {
            _AgentMiningReleaseInterval = releaseInterval;
        }
        _AgentMiningRateInterval = rateInterval;
        _AgentMiningAllowReleaseTime = allowReleaseTime;
        _lastAgentMiningRateTime = lastRateTime;

        emit eveMigrationCompleted(_oldContractAddress, block.timestamp);
    }

    /**
     * @dev Check if migration has been completed
     */
    function isMigrationCompleted() public view returns (bool) {
        return _migrationCompleted;
    }

    /**
     * @dev Get the old contract address used for migration
     */
    function getOldContractAddress() public view returns (address) {
        return _oldContractAddress;
    }

    /**
     * @dev Get all migration-related state for verification
     */
    function getMigrationState() public view returns (bool migrationCompleted, address oldContractAddress, uint256 migratedTotalAward, uint256 migratedCurrAward, uint256 migratedTGETimestamp) {
        return (_migrationCompleted, _oldContractAddress, _AgentMiningTotalAward, _AgentMiningCurrAward, _TGE_timestamp);
    }
}
