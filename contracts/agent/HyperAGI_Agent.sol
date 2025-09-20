// SPDX-License-Identifier: MIT
/**
 * @title HyperAGI_Agent
 * @dev This is an upgradeable contract for managing AI agents in the HyperAGI ecosystem
 * Features include agent minting, wallet allocation, energy recharge, and time period management
 * Agents are created from POP NFTs and assigned unique wallet addresses from a pool
 *
 * @dev Upgrade History:
 * - 2025-09-05: Added wallet address allocation functionality in mint methods
 * - 2025-09-10: Added total count and online count management functionality with admin-only setter and getter
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract IERC1155 {
    function burn(address account, uint256 id, uint256 value) public {}

    function balanceOf(address account, uint256 id) public view returns (uint256) {}
}

// Simplified StrUtil abstract contract - only includes used functionality
abstract contract IStrUtil {
    function toHexString(address addr) public pure virtual returns (string memory);
}

// Simplified Roles_Cfg abstract contract - only includes used functionality
abstract contract IHyperAGI_Roles_Cfg {
    function hasAdminRole(address account) public view virtual returns (bool);
}

// Simplified Storage abstract contract - only includes used functionality
abstract contract IHyperAGI_Storage {
    function getUint(string memory key) public view virtual returns (uint256);

    function setUint(string memory key, uint256 value) public virtual;

    function getNextId() public virtual returns (uint256);

    function setBytes32Uint(bytes32 key, uint256 value) public virtual;

    function genKey(string memory prefix, uint256 id) public pure virtual returns (string memory);

    function setString(string memory key, string memory value) public virtual;

    function getString(string memory key) public view virtual returns (string memory);

    function setBytes32(string memory key, bytes32 value) public virtual;

    function getBool(string memory key) public view virtual returns (bool);

    function setBool(string memory key, bool value) public virtual;

    function setAddressArray(string memory key, address value) public virtual returns (uint256);

    function setAddress(string memory key, address value) public virtual;

    function getAddress(string memory key) public view virtual returns (address);

    function getBytes32Uint(bytes32 key) public view virtual returns (uint256);

    function getAddressArray(string memory key, uint256 index) public view virtual returns (address);

    function getAddressArrayLen(string memory key) public view virtual returns (uint256);
}

interface IHyperAGI_Agent_Wallet {
    function allocateWallet() external payable returns (address);
}

contract HyperAGI_Agent is OwnableUpgradeable {
    using Strings for *;

    // Helper function: convert address to hexadecimal string
    function _toHexString(address addr) internal pure returns (string memory) {
        return Strings.toHexString(uint160(addr), 20);
    }

    // Original state variables - order must remain unchanged
    address public _rolesCfgAddress;
    address public _storageAddress;
    address public _agentPOPNFTAddress;
    address public _groundRodAddress;

    uint256[] private groundRodLevelKeys;
    mapping(uint256 => uint256) public _groundRodLevels;

    address public _agentWalletAddress;

    // Time period structure
    struct TimePeriod {
        uint256 startTime; // Start time (timestamp)
        uint256 endTime; // End time (timestamp)
    }

    event eveSaveAgent(bytes32 sid);
    event eveRechargeEnergy(bytes32 sid, uint256 groundRodLevelId);
    event eveAccountRechargeEnergy(address account, uint256 groundRodLevelId);
    event eveAgentAccount(address account, uint256 index);
    event eveTimePeriodUpdated(bytes32 sid, uint256 startTime, uint256 endTime);
    event eveTotalCountUpdated(uint256 totalCount);
    event eveOnlineCountUpdated(uint256 onlineCount);

    // Admin role check modifier
    modifier onlyAdmin() {
        require(_rolesCfgAddress != address(0), "roles config not set");

        IHyperAGI_Roles_Cfg rolesCfg = IHyperAGI_Roles_Cfg(_rolesCfgAddress);
        require(rolesCfg.hasAdminRole(msg.sender) || msg.sender == owner(), "not admin role");
        _;
    }

    function initialize(address onlyOwner) public initializer {
        __Ownable_init(onlyOwner);
    }

    function setRolesCfgAddress(address rolesCfgAddress) public onlyOwner {
        _rolesCfgAddress = rolesCfgAddress;
    }

    function setStorageAddress(address storageAddress) public onlyOwner {
        _storageAddress = storageAddress;
    }

    function setAgentPOPNFTAddress(address agentPOPNFTAddress) public onlyOwner {
        _agentPOPNFTAddress = agentPOPNFTAddress;
    }

    function setGroundRodAddress(address groundRodAddress) public onlyOwner {
        _groundRodAddress = groundRodAddress;
    }

    function setAgentWalletAddress(address agentWalletAddress) public onlyOwner {
        _agentWalletAddress = agentWalletAddress;
    }

    function setContractAddress(address[] memory contractaddressArray) public onlyOwner {
        _rolesCfgAddress = contractaddressArray[0];
        _storageAddress = contractaddressArray[1];
        _agentPOPNFTAddress = contractaddressArray[2];
        _groundRodAddress = contractaddressArray[3];
        _agentWalletAddress = contractaddressArray[4];
    }

    function setGroundRodLevels(uint256[] memory tokenIds, uint256[] memory levels) public onlyOwner {
        for (uint i = 0; i < groundRodLevelKeys.length; i++) {
            delete _groundRodLevels[groundRodLevelKeys[i]];
        }

        groundRodLevelKeys = tokenIds;

        for (uint i = 0; i < tokenIds.length; i++) {
            _groundRodLevels[tokenIds[i]] = levels[i];
        }
    }

    function mint(uint256 tokenId, string memory avatar, string memory nickName, string memory personalization) public {
        // require(IERC721(_agentPOPNFTAddress).ownerOf(tokenId) == msg.sender, "not owner");

        // IHyperAGI_Storage storageAddress = IHyperAGI_Storage(_storageAddress);

        // require(storageAddress.getUint(tokenId.toString()) == 0, "already minted");

        // storageAddress.setUint(tokenId.toString(), 1);

        // uint256 id = storageAddress.getNextId();

        // bytes32 sid = generateUniqueHash(id);
        // storageAddress.setBytes32Uint(sid, id);

        // storageAddress.setUint(storageAddress.genKey("tokenId", id), tokenId);

        // storageAddress.setString(storageAddress.genKey("avatar", id), avatar);

        // storageAddress.setString(storageAddress.genKey("nickName", id), nickName);
        // storageAddress.setString(storageAddress.genKey("personalization", id), personalization);

        // storageAddress.setBytes32(storageAddress.genKey("sid", id), sid);

        // if (!storageAddress.getBool(_toHexString(msg.sender))) {
        //     storageAddress.setBool(_toHexString(msg.sender), true);
        //     uint256 index = storageAddress.setAddressArray("agentAccountList", msg.sender);

        //     emit eveAgentAccount(msg.sender, index);
        // }

        // storageAddress.setUint(storageAddress.genKey("groundRodLevel", id), 5);

        // storageAddress.setUint(string(abi.encodePacked("groundRodLevel", "_", _toHexString(msg.sender))), 5);
        // emit eveAccountRechargeEnergy(msg.sender, 5);
        // emit eveRechargeEnergy(sid, 1);

        // emit eveSaveAgent(sid);
        revert("not supported");
    }

    function mintV2(uint256 /* tokenId */, string memory /* avatar */, string memory /* nickName */, string memory /* personalization */, string memory /* welcomeMessage */) public pure {
        revert("not supported");
    }

    function adminMintV3(uint256 tokenId, string[] memory strParams) public payable onlyAdmin {
        IHyperAGI_Storage storageAddress = IHyperAGI_Storage(_storageAddress);

        address owner = IERC721(_agentPOPNFTAddress).ownerOf(tokenId);

        require(storageAddress.getUint(tokenId.toString()) == 0, "already minted");

        storageAddress.setUint(tokenId.toString(), 1);

        uint256 id = storageAddress.getNextId();

        bytes32 sid = generateUniqueHash(id);
        storageAddress.setBytes32Uint(sid, id);

        storageAddress.setUint(storageAddress.genKey("tokenId", id), tokenId);

        storageAddress.setString(storageAddress.genKey("avatar", id), strParams[0]);

        storageAddress.setString(storageAddress.genKey("nickName", id), strParams[1]);
        storageAddress.setString(storageAddress.genKey("personalization", id), strParams[2]);
        storageAddress.setString(storageAddress.genKey("welcomeMessage", id), strParams[3]);

        storageAddress.setBytes32(storageAddress.genKey("sid", id), sid);

        if (!storageAddress.getBool(_toHexString(owner))) {
            storageAddress.setBool(_toHexString(owner), true);
            uint256 index = storageAddress.setAddressArray("agentAccountList", owner);

            emit eveAgentAccount(owner, index);
        }

        storageAddress.setUint(storageAddress.genKey("groundRodLevel", id), 5);

        storageAddress.setUint(string(abi.encodePacked("groundRodLevel", "_", _toHexString(msg.sender))), 5);

        // Set default time period (current time to 6.4 minutes later)
        uint256 currentTime = block.timestamp;
        uint256 defaultEndTime = currentTime + 384; // Default 6.4 minutes validity period (384 seconds)
        storageAddress.setUint(storageAddress.genKey("timePeriodStart", id), currentTime);
        storageAddress.setUint(storageAddress.genKey("timePeriodEnd", id), defaultEndTime);

        // Allocate wallet through wallet contract
        if (_agentWalletAddress != address(0)) {
            IHyperAGI_Agent_Wallet agentWallet = IHyperAGI_Agent_Wallet(_agentWalletAddress);
            address walletAddress = agentWallet.allocateWallet{value: msg.value}();

            storageAddress.setAddress(storageAddress.genKey("walletAddress", id), walletAddress);
        }

        emit eveAccountRechargeEnergy(msg.sender, 5);
        emit eveRechargeEnergy(sid, 1);

        emit eveSaveAgent(sid);
    }

    function bindWallet(bytes32 sid) public onlyAdmin {
        IHyperAGI_Storage storageAddress = IHyperAGI_Storage(_storageAddress);

        uint256 id = storageAddress.getBytes32Uint(sid);

        require(id > 0, "not found");

        address walletAddress = storageAddress.getAddress(storageAddress.genKey("walletAddress", id));
        if (walletAddress != address(0)) {
            return;
        }

        // Set default time period (current time to 6.4 minutes later)
        uint256 currentTime = block.timestamp;
        uint256 defaultEndTime = currentTime + 384; // Default 6.4 minutes validity period (384 seconds)
        storageAddress.setUint(storageAddress.genKey("timePeriodStart", id), currentTime);
        storageAddress.setUint(storageAddress.genKey("timePeriodEnd", id), defaultEndTime);

        // Allocate wallet through wallet contract
        if (_agentWalletAddress != address(0)) {
            IHyperAGI_Agent_Wallet agentWallet = IHyperAGI_Agent_Wallet(_agentWalletAddress);
            walletAddress = agentWallet.allocateWallet{value: 0}();

            storageAddress.setAddress(storageAddress.genKey("walletAddress", id), walletAddress);
        }

        emit eveSaveAgent(sid);
    }

    function batchBindWallet(bytes32[] memory sids) public onlyAdmin {
        for (uint256 i = 0; i < sids.length; i++) {
            bindWallet(sids[i]);
        }
    }

    function mintV3(uint256 tokenId, string[] memory strParams) public payable {
        // require(IERC721(_agentPOPNFTAddress).ownerOf(tokenId) == msg.sender, "not owner");

        address owner = IERC721(_agentPOPNFTAddress).ownerOf(tokenId);

        IHyperAGI_Storage storageAddress = IHyperAGI_Storage(_storageAddress);

        require(storageAddress.getUint(tokenId.toString()) == 0, "already minted");

        storageAddress.setUint(tokenId.toString(), 1);

        uint256 id = storageAddress.getNextId();

        bytes32 sid = generateUniqueHash(id);
        storageAddress.setBytes32Uint(sid, id);

        storageAddress.setUint(storageAddress.genKey("tokenId", id), tokenId);

        storageAddress.setString(storageAddress.genKey("avatar", id), strParams[0]);

        storageAddress.setString(storageAddress.genKey("nickName", id), strParams[1]);
        storageAddress.setString(storageAddress.genKey("personalization", id), strParams[2]);
        storageAddress.setString(storageAddress.genKey("welcomeMessage", id), strParams[3]);

        storageAddress.setBytes32(storageAddress.genKey("sid", id), sid);

        if (!storageAddress.getBool(_toHexString(owner))) {
            storageAddress.setBool(_toHexString(owner), true);
            uint256 index = storageAddress.setAddressArray("agentAccountList", owner);

            emit eveAgentAccount(owner, index);
        }

        storageAddress.setUint(storageAddress.genKey("groundRodLevel", id), 5);

        storageAddress.setUint(string(abi.encodePacked("groundRodLevel", "_", _toHexString(msg.sender))), 5);

        // Set default time period (current time to 6.4 minutes later)
        uint256 currentTime = block.timestamp;
        uint256 defaultEndTime = currentTime + 384; // Default 6.4 minutes validity period (384 seconds)
        storageAddress.setUint(storageAddress.genKey("timePeriodStart", id), currentTime);
        storageAddress.setUint(storageAddress.genKey("timePeriodEnd", id), defaultEndTime);

        // Allocate wallet through wallet contract
        if (_agentWalletAddress != address(0)) {
            IHyperAGI_Agent_Wallet agentWallet = IHyperAGI_Agent_Wallet(_agentWalletAddress);
            address walletAddress = agentWallet.allocateWallet{value: msg.value}();

            storageAddress.setAddress(storageAddress.genKey("walletAddress", id), walletAddress);
        }

        emit eveAccountRechargeEnergy(msg.sender, 5);
        emit eveRechargeEnergy(sid, 1);

        emit eveSaveAgent(sid);
    }

    function update(bytes32 sid, string memory avatar, string memory nickName, string memory personalization) public {
        // IHyperAGI_Storage storageAddress = IHyperAGI_Storage(_storageAddress);

        // uint256 id = storageAddress.getBytes32Uint(sid);

        // require(id > 0, "not found");

        // uint256 tokenId = storageAddress.getUint(storageAddress.genKey("tokenId", id));

        // require(IERC721(_agentPOPNFTAddress).ownerOf(tokenId) == msg.sender, "not owner");

        // storageAddress.setString(storageAddress.genKey("avatar", id), avatar);

        // storageAddress.setString(storageAddress.genKey("nickName", id), nickName);
        // storageAddress.setString(storageAddress.genKey("personalization", id), personalization);

        // if (!storageAddress.getBool(_toHexString(msg.sender))) {
        //     storageAddress.setBool(_toHexString(msg.sender), true);
        //     uint256 index = storageAddress.setAddressArray("agentAccountList", msg.sender);

        //     emit eveAgentAccount(msg.sender, index);
        // }

        // emit eveSaveAgent(sid);

        revert("not supported");
    }

    function updateV2(bytes32 /* sid */, string memory /* avatar */, string memory /* nickName */, string memory /* personalization */, string memory /* welcomeMessage */) public pure {
        revert("not supported");
    }

    function updateV3(bytes32 sid, string[] memory strParams) public {
        IHyperAGI_Storage storageAddress = IHyperAGI_Storage(_storageAddress);
        uint256 id = storageAddress.getBytes32Uint(sid);
        update(sid, strParams[0], strParams[1], strParams[2]);

        storageAddress.setString(storageAddress.genKey("welcomeMessage", id), strParams[3]);
    }

    function getAgent(bytes32 sid) public view returns (uint256, string memory, string memory, string memory, uint256) {
        // IHyperAGI_Storage storageAddress = IHyperAGI_Storage(_storageAddress);

        // uint256 id = storageAddress.getBytes32Uint(sid);

        // require(id > 0, "not found");

        // return (
        //     storageAddress.getUint(storageAddress.genKey("tokenId", id)),
        //     storageAddress.getString(storageAddress.genKey("avatar", id)),
        //     storageAddress.getString(storageAddress.genKey("nickName", id)),
        //     storageAddress.getString(storageAddress.genKey("personalization", id)),
        //     storageAddress.getUint(storageAddress.genKey("groundRodLevel", id))
        // );
        revert("not supported");
    }

    function getAgentV2(bytes32 sid) public view returns (uint256, string memory, string memory, string memory, string memory, uint256) {
        // IHyperAGI_Storage storageAddress = IHyperAGI_Storage(_storageAddress);

        // uint256 id = storageAddress.getBytes32Uint(sid);

        // require(id > 0, "not found");

        // return (
        //     storageAddress.getUint(storageAddress.genKey("tokenId", id)),
        //     storageAddress.getString(storageAddress.genKey("avatar", id)),
        //     storageAddress.getString(storageAddress.genKey("nickName", id)),
        //     storageAddress.getString(storageAddress.genKey("personalization", id)),
        //     storageAddress.getString(storageAddress.genKey("welcomeMessage", id)),
        //     storageAddress.getUint(storageAddress.genKey("groundRodLevel", id))
        // );
        revert("not supported");
    }

    function getAgentWallet(bytes32 sid) public view returns (address) {
        // Fallback to storage if wallet contract not set
        IHyperAGI_Storage storageAddress = IHyperAGI_Storage(_storageAddress);
        uint256 id = storageAddress.getBytes32Uint(sid);
        require(id > 0, "not found");

        return storageAddress.getAddress(storageAddress.genKey("walletAddress", id));
    }

    function getAgentV3(bytes32 sid) public view returns (uint256, string memory, string memory, string memory, string memory, uint256, address, uint256, uint256) {
        IHyperAGI_Storage storageAddress = IHyperAGI_Storage(_storageAddress);

        uint256 id = storageAddress.getBytes32Uint(sid);

        require(id > 0, "not found");

        address walletAddress = storageAddress.getAddress(storageAddress.genKey("walletAddress", id));
        return (
            storageAddress.getUint(storageAddress.genKey("tokenId", id)),
            storageAddress.getString(storageAddress.genKey("avatar", id)),
            storageAddress.getString(storageAddress.genKey("nickName", id)),
            storageAddress.getString(storageAddress.genKey("personalization", id)),
            storageAddress.getString(storageAddress.genKey("welcomeMessage", id)),
            storageAddress.getUint(storageAddress.genKey("groundRodLevel", id)),
            walletAddress,
            storageAddress.getUint(storageAddress.genKey("timePeriodStart", id)),
            storageAddress.getUint(storageAddress.genKey("timePeriodEnd", id))
        );
    }

    function rechargeEnergy(uint256 tokenId, bytes32 sid) public {
        IHyperAGI_Storage storageAddress = IHyperAGI_Storage(_storageAddress);

        (uint256 agentTokenId, , , , ) = getAgent(sid);

        uint256 id = storageAddress.getBytes32Uint(sid);

        require(IERC721(_agentPOPNFTAddress).ownerOf(agentTokenId) == msg.sender, "not owner");

        uint256 groundRodLevel = _groundRodLevels[tokenId];

        require(groundRodLevel > 0, "not found");

        // Check if the user has enough ERC-1155 tokens to burn
        uint256 userBalance = IERC1155(_groundRodAddress).balanceOf(msg.sender, tokenId);
        require(userBalance >= 1, "insufficient token balance");

        // Burn the token
        IERC1155(_groundRodAddress).burn(msg.sender, tokenId, 1);

        storageAddress.setUint(storageAddress.genKey("groundRodLevel", id), groundRodLevel);

        storageAddress.setUint(string(abi.encodePacked("groundRodLevel", "_", _toHexString(msg.sender))), groundRodLevel);

        emit eveAccountRechargeEnergy(msg.sender, groundRodLevel);
        emit eveRechargeEnergy(sid, groundRodLevel);
    }

    function generateUniqueHash(uint256 nextId) private view returns (bytes32) {
        return keccak256(abi.encodePacked(block.timestamp, block.prevrandao, nextId));
    }

    function getAgentAccount(uint256 index) public view returns (address) {
        IHyperAGI_Storage storageAddress = IHyperAGI_Storage(_storageAddress);

        return storageAddress.getAddressArray("agentAccountList", index);
    }

    function getAgentAccountLen() public view returns (uint256) {
        IHyperAGI_Storage storageAddress = IHyperAGI_Storage(_storageAddress);

        return storageAddress.getAddressArrayLen("agentAccountList");
    }

    function getGroundRodLevel(address account) public view returns (uint256) {
        IHyperAGI_Storage storageAddress = IHyperAGI_Storage(_storageAddress);
        string memory key = string(abi.encodePacked("groundRodLevel", "_", _toHexString(account)));

        return storageAddress.getUint(key);
    }

    // Admin modify agent's time period
    function updateAgentTimePeriod(bytes32 sid, uint256 startTime, uint256 endTime) public onlyAdmin {
        require(startTime < endTime, "start time must be before end time");
        require(endTime > block.timestamp, "end time must be in the future");

        IHyperAGI_Storage storageAddress = IHyperAGI_Storage(_storageAddress);
        uint256 id = storageAddress.getBytes32Uint(sid);
        require(id > 0, "agent not found");

        storageAddress.setUint(storageAddress.genKey("timePeriodStart", id), startTime);
        storageAddress.setUint(storageAddress.genKey("timePeriodEnd", id), endTime);

        emit eveTimePeriodUpdated(sid, startTime, endTime);
    }

    // Get agent's time period information
    function getAgentTimePeriod(bytes32 sid) public view returns (uint256 startTime, uint256 endTime) {
        IHyperAGI_Storage storageAddress = IHyperAGI_Storage(_storageAddress);
        uint256 id = storageAddress.getBytes32Uint(sid);
        require(id > 0, "agent not found");

        startTime = storageAddress.getUint(storageAddress.genKey("timePeriodStart", id));
        endTime = storageAddress.getUint(storageAddress.genKey("timePeriodEnd", id));
    }

    // Check if agent is within valid time period
    function isAgentActive(bytes32 sid) public view returns (bool) {
        (uint256 startTime, uint256 endTime) = getAgentTimePeriod(sid);
        uint256 currentTime = block.timestamp;
        return currentTime >= startTime && currentTime <= endTime;
    }

    // Set total count and online count (only admin can call)
    function setCounts(uint256 totalCount, uint256 onlineCount) public onlyAdmin {
        IHyperAGI_Storage storageAddress = IHyperAGI_Storage(_storageAddress);
        storageAddress.setUint("totalCount", totalCount);
        storageAddress.setUint("onlineCount", onlineCount);
        emit eveTotalCountUpdated(totalCount);
        emit eveOnlineCountUpdated(onlineCount);
    }

    // Internal method for contract-to-contract calls
    function setCountsInternal(uint256 totalCount, uint256 onlineCount) external {
        IHyperAGI_Storage storageAddress = IHyperAGI_Storage(_storageAddress);
        storageAddress.setUint("totalCount", totalCount);
        storageAddress.setUint("onlineCount", onlineCount);
        emit eveTotalCountUpdated(totalCount);
        emit eveOnlineCountUpdated(onlineCount);
    }

    // Get total count
    function getTotalCount() public view returns (uint256) {
        IHyperAGI_Storage storageAddress = IHyperAGI_Storage(_storageAddress);
        return storageAddress.getUint("totalCount");
    }

    // Get online count
    function getOnlineCount() public view returns (uint256) {
        IHyperAGI_Storage storageAddress = IHyperAGI_Storage(_storageAddress);
        return storageAddress.getUint("onlineCount");
    }
}
