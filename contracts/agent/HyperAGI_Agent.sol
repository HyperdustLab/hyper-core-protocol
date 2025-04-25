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

    address public _rolesCfgAddress;
    address public _storageAddress;
    address public _agentPOPNFTAddress;
    address public _groundRodAddress;

    uint256[] private groundRodLevelKeys;
    mapping(uint256 => uint256) public _groundRodLevels;

    event eveSaveAgent(bytes32 sid);
    event eveRechargeEnergy(bytes32 sid, uint256 groundRodLevelId);
    event eveAccountRechargeEnergy(address account, uint256 groundRodLevelId);
    event eveAgentAccount(address account, uint256 index);

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

    function mintV3(uint256 tokenId, string[] memory strParams) public {
        require(IERC721(_agentPOPNFTAddress).ownerOf(tokenId) == msg.sender, "not owner");

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
}
