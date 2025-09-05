
// SPDX-License-Identifier: UNLICENSED
/**
 * ONLY FOR TEST PURPOSE, NOT FOR PRODUCTION！！
 * 
 * @title HyperAGI_Agent
 * @dev This is an upgradeable contract for managing AI agents in the HyperAGI ecosystem
 * Features include agent minting, wallet allocation, energy recharge, and time period management
 * Agents are created from POP NFTs and assigned unique wallet addresses from a pool
 * 
 * @dev Upgrade History:
 * - 2025-09-05: Added wallet address allocation functionality in mint methods
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../utils/StrUtil.sol";
import "../HyperAGI_Roles_Cfg.sol";
import "../HyperAGI_Storage.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract IERC1155 {
    function burn(address account, uint256 id, uint256 value) public {}

    function balanceOf(address account, uint256 id) public view returns (uint256) {}
}

contract HyperAGI_Agent is OwnableUpgradeable {
    using Strings for *;
    using StrUtil for *;

    // Time period structure
    struct TimePeriod {
        uint256 startTime;  // Start time (timestamp)
        uint256 endTime;    // End time (timestamp)
    }

    address public _rolesCfgAddress;
    address public _storageAddress;
    address public _agentPOPNFTAddress;
    address public _groundRodAddress;

    uint256[] private groundRodLevelKeys;
    mapping(uint256 => uint256) public _groundRodLevels;

    // Wallet address pool related variables
    address[] public walletAddressPool;
    mapping(address => bool) public allocatedWallets;
    mapping(address => bool) public walletInPool;
    uint256 public nextWalletIndex;
    uint256 public defaultTransferAmount ; // Default transfer amount 1 ETH

    event eveSaveAgent(bytes32 sid);
    event eveRechargeEnergy(bytes32 sid, uint256 groundRodLevelId);
    event eveAccountRechargeEnergy(address account, uint256 groundRodLevelId);
    event eveAgentAccount(address account, uint256 index);
    event eveWalletAllocated(bytes32 sid, address walletAddress, uint256 transferAmount);
    event eveWalletAdded(address walletAddress);
    event eveTransferAmountUpdated(uint256 newAmount);
    event eveTimePeriodUpdated(bytes32 sid, uint256 startTime, uint256 endTime);

    // Admin role check modifier
    modifier onlyAdmin() {
        require(_rolesCfgAddress != address(0), "roles config not set");
        HyperAGI_Roles_Cfg rolesCfg = HyperAGI_Roles_Cfg(_rolesCfgAddress);
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

    function setContractAddress(address[] memory contractaddressArray) public onlyOwner {
        _rolesCfgAddress = contractaddressArray[0];
        _storageAddress = contractaddressArray[1];
        _agentPOPNFTAddress = contractaddressArray[2];
        _groundRodAddress = contractaddressArray[3];
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

    // Add wallet addresses to address pool (admin only)
    function addWalletToPool(address[] memory walletAddresses) public onlyAdmin {
        for (uint i = 0; i < walletAddresses.length; i++) {
            address wallet = walletAddresses[i];
            require(wallet != address(0), "invalid wallet address");
            require(!walletInPool[wallet], "wallet already in pool");
            require(!allocatedWallets[wallet], "wallet already allocated");
            
            walletAddressPool.push(wallet);
            walletInPool[wallet] = true;
            
            emit eveWalletAdded(wallet);
        }
    }

    // Set default transfer amount (admin only)
    function setDefaultTransferAmount(uint256 amount) public onlyAdmin {
        defaultTransferAmount = amount;
        emit eveTransferAmountUpdated(amount);
    }

    // Get next available wallet address
    function getNextAvailableWallet() private returns (address) {
        require(walletAddressPool.length > 0, "no wallets in pool");
        require(nextWalletIndex < walletAddressPool.length, "no available wallets");
        
        address wallet = walletAddressPool[nextWalletIndex];
        require(!allocatedWallets[wallet], "wallet already allocated");
        
        allocatedWallets[wallet] = true;
        nextWalletIndex++;
        
        return wallet;
    }

    // Check wallet address pool status
    function getWalletPoolInfo() public view returns (uint256 totalWallets, uint256 allocatedWallets, uint256 availableWallets) {
        totalWallets = walletAddressPool.length;
        allocatedWallets = nextWalletIndex;
        availableWallets = totalWallets - allocatedWallets;
    }

    // Get all addresses in wallet address pool
    function getWalletPool() public view returns (address[] memory) {
        return walletAddressPool;
    }

    // Check if wallet is allocated
    function isWalletAllocated(address wallet) public view returns (bool) {
        return allocatedWallets[wallet];
    }

    function mint(uint256 tokenId, string memory avatar, string memory nickName, string memory personalization) public {
        require(IERC721(_agentPOPNFTAddress).ownerOf(tokenId) == msg.sender, "not owner");

        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);

        require(storageAddress.getUint(tokenId.toString()) == 0, "already minted");

        storageAddress.setUint(tokenId.toString(), 1);

        uint256 id = storageAddress.getNextId();

        bytes32 sid = generateUniqueHash(id);
        storageAddress.setBytes32Uint(sid, id);

        storageAddress.setUint(storageAddress.genKey("tokenId", id), tokenId);

        storageAddress.setString(storageAddress.genKey("avatar", id), avatar);

        storageAddress.setString(storageAddress.genKey("nickName", id), nickName);
        storageAddress.setString(storageAddress.genKey("personalization", id), personalization);

        storageAddress.setBytes32(storageAddress.genKey("sid", id), sid);


        address allocatedWallet = getNextAvailableWallet();
        storageAddress.setAddress(storageAddress.genKey("walletAddress", id), allocatedWallet);


        if (!storageAddress.getBool(msg.sender.toHexString())) {
            storageAddress.setBool(msg.sender.toHexString(), true);
            uint256 index = storageAddress.setAddressArray("agentAccountList", msg.sender);

            emit eveAgentAccount(msg.sender, index);
        }

        storageAddress.setUint(storageAddress.genKey("groundRodLevel", id), 5);

        storageAddress.setUint(string(abi.encodePacked("groundRodLevel", "_", msg.sender.toHexString())), 5);
        emit eveAccountRechargeEnergy(msg.sender, 5);
        emit eveRechargeEnergy(sid, 1);

        emit eveSaveAgent(sid);
    }

    function mintV2(uint256 tokenId, string memory avatar, string memory nickName, string memory personalization, string memory welcomeMessage) public {
        revert("not supported");
    }

    function mintV3(uint256 tokenId, string[] memory strParams) public payable {
        // require(IERC721(_agentPOPNFTAddress).ownerOf(tokenId) == msg.sender, "not owner");

        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);

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

        // Allocate wallet address
        address allocatedWallet = getNextAvailableWallet();
        storageAddress.setAddress(storageAddress.genKey("walletAddress", id), allocatedWallet);

        if (!storageAddress.getBool(msg.sender.toHexString())) {
            storageAddress.setBool(msg.sender.toHexString(), true);
            uint256 index = storageAddress.setAddressArray("agentAccountList", msg.sender);

            emit eveAgentAccount(msg.sender, index);
        }

        storageAddress.setUint(storageAddress.genKey("groundRodLevel", id), 5);

        storageAddress.setUint(string(abi.encodePacked("groundRodLevel", "_", msg.sender.toHexString())), 5);

        // Set default time period (current time to 6.4 minutes later)
        uint256 currentTime = block.timestamp;
        uint256 defaultEndTime = currentTime + 384; // Default 6.4 minutes validity period (384 seconds)
        storageAddress.setUint(storageAddress.genKey("timePeriodStart", id), currentTime);
        storageAddress.setUint(storageAddress.genKey("timePeriodEnd", id), defaultEndTime);

        emit eveAccountRechargeEnergy(msg.sender, 5);

        emit eveRechargeEnergy(sid, 1);

        // Transfer to allocated wallet address
        if (address(this).balance >= defaultTransferAmount) {
            (bool success, ) = allocatedWallet.call{value: defaultTransferAmount}("");
            require(success, "transfer failed");
            emit eveWalletAllocated(sid, allocatedWallet, defaultTransferAmount);
        }

        emit eveSaveAgent(sid);
    }

    function update(bytes32 sid, string memory avatar, string memory nickName, string memory personalization) public {
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);

        uint256 id = storageAddress.getBytes32Uint(sid);

        require(id > 0, "not found");

        uint256 tokenId = storageAddress.getUint(storageAddress.genKey("tokenId", id));

        require(IERC721(_agentPOPNFTAddress).ownerOf(tokenId) == msg.sender, "not owner");

        storageAddress.setString(storageAddress.genKey("avatar", id), avatar);

        storageAddress.setString(storageAddress.genKey("nickName", id), nickName);
        storageAddress.setString(storageAddress.genKey("personalization", id), personalization);

        if (!storageAddress.getBool(msg.sender.toHexString())) {
            storageAddress.setBool(msg.sender.toHexString(), true);
            uint256 index = storageAddress.setAddressArray("agentAccountList", msg.sender);

            emit eveAgentAccount(msg.sender, index);
        }

        emit eveSaveAgent(sid);
    }

    function updateV2(bytes32 sid, string memory avatar, string memory nickName, string memory personalization, string memory welcomeMessage) public {
        revert("not supported");
    }

    function updateV3(bytes32 sid, string[] memory strParams) public {
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);
        uint256 id = storageAddress.getBytes32Uint(sid);
        update(sid, strParams[0], strParams[1], strParams[2]);

        storageAddress.setString(storageAddress.genKey("welcomeMessage", id), strParams[3]);
    }

    function getAgent(bytes32 sid) public view returns (uint256, string memory, string memory, string memory, uint256) {
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);

        uint256 id = storageAddress.getBytes32Uint(sid);

        require(id > 0, "not found");

        return (
            storageAddress.getUint(storageAddress.genKey("tokenId", id)),
            storageAddress.getString(storageAddress.genKey("avatar", id)),
            storageAddress.getString(storageAddress.genKey("nickName", id)),
            storageAddress.getString(storageAddress.genKey("personalization", id)),
            storageAddress.getUint(storageAddress.genKey("groundRodLevel", id))
        );
    }

    function getAgentV2(bytes32 sid) public view returns (uint256, string memory, string memory, string memory, string memory, uint256) {
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);

        uint256 id = storageAddress.getBytes32Uint(sid);

        require(id > 0, "not found");

        return (
            storageAddress.getUint(storageAddress.genKey("tokenId", id)),
            storageAddress.getString(storageAddress.genKey("avatar", id)),
            storageAddress.getString(storageAddress.genKey("nickName", id)),
            storageAddress.getString(storageAddress.genKey("personalization", id)),
            storageAddress.getString(storageAddress.genKey("welcomeMessage", id)),
            storageAddress.getUint(storageAddress.genKey("groundRodLevel", id))
        );
    }


    function getAgentWallet(bytes32 sid) public view returns (address) {
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);
        uint256 id = storageAddress.getBytes32Uint(sid);
        require(id > 0, "not found");
        
        return storageAddress.getAddress(storageAddress.genKey("walletAddress", id));
    }


    function getAgentV3(bytes32 sid) public view returns (uint256, string memory, string memory, string memory, string memory, uint256, address, uint256, uint256) {
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);

        uint256 id = storageAddress.getBytes32Uint(sid);

        require(id > 0, "not found");

        return (
            storageAddress.getUint(storageAddress.genKey("tokenId", id)),
            storageAddress.getString(storageAddress.genKey("avatar", id)),
            storageAddress.getString(storageAddress.genKey("nickName", id)),
            storageAddress.getString(storageAddress.genKey("personalization", id)),
            storageAddress.getString(storageAddress.genKey("welcomeMessage", id)),
            storageAddress.getUint(storageAddress.genKey("groundRodLevel", id)),
            storageAddress.getAddress(storageAddress.genKey("walletAddress", id)),
            storageAddress.getUint(storageAddress.genKey("timePeriodStart", id)),
            storageAddress.getUint(storageAddress.genKey("timePeriodEnd", id))
        );
    }

    function rechargeEnergy(uint256 tokenId, bytes32 sid) public {
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);

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

        storageAddress.setUint(string(abi.encodePacked("groundRodLevel", "_", msg.sender.toHexString())), groundRodLevel);

        emit eveAccountRechargeEnergy(msg.sender, groundRodLevel);
        emit eveRechargeEnergy(sid, groundRodLevel);
    }

    function generateUniqueHash(uint256 nextId) private view returns (bytes32) {
        return keccak256(abi.encodePacked(block.timestamp, block.difficulty, nextId));
    }

    function getAgentAccount(uint256 index) public view returns (address) {
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);

        return storageAddress.getAddressArray("agentAccountList", index);
    }

    function getAgentAccountLen() public view returns (uint256) {
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);

        return storageAddress.getAddressArrayLen("agentAccountList");
    }

    function getGroundRodLevel(address account) public view returns (uint256) {
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);
        string memory key = string(abi.encodePacked("groundRodLevel", "_", account.toHexString()));

        return storageAddress.getUint(key);
    }

    // Admin modify agent's time period
    function updateAgentTimePeriod(bytes32 sid, uint256 startTime, uint256 endTime) public onlyAdmin {
        require(startTime < endTime, "start time must be before end time");
        require(endTime > block.timestamp, "end time must be in the future");

        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);
        uint256 id = storageAddress.getBytes32Uint(sid);
        require(id > 0, "agent not found");

        storageAddress.setUint(storageAddress.genKey("timePeriodStart", id), startTime);
        storageAddress.setUint(storageAddress.genKey("timePeriodEnd", id), endTime);

        emit eveTimePeriodUpdated(sid, startTime, endTime);
    }

    // Get agent's time period information
    function getAgentTimePeriod(bytes32 sid) public view returns (uint256 startTime, uint256 endTime) {
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);
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

    // Allow contract to receive ETH
    receive() external payable {}
}
