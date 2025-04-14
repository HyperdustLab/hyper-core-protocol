pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import {StrUtil} from "../utils/StrUtil.sol";

import "./../HyperAGI_Storage.sol";

import "./HyperAGI_Miner_NFT_Pledge.sol";

contract HyperAGI_Node_Mgr is OwnableUpgradeable {
    using Strings for *;
    using StrUtil for *;

    address public _rolesCfgAddress;
    address public _storageAddress;
    address public _minerNFTPledgeAddress;

    event eveSave(uint256[] idList, string[] portList, uint256 fee);
    event eveActive(uint256 id, uint256 index);

    event eveSave(uint256 id);

    event eveDelete(uint256 id);

    function initialize(address onlyOwner) public initializer {
        __Ownable_init(onlyOwner);
    }

    function setRolesCfgAddress(address rolesCfgAddress) public onlyOwner {
        _rolesCfgAddress = rolesCfgAddress;
    }

    function setStorageAddress(address storageAddress) public onlyOwner {
        _storageAddress = storageAddress;
    }

    function setMinerNFTPledgeAddress(address minerNFTPledgeAddress) public onlyOwner {
        _minerNFTPledgeAddress = minerNFTPledgeAddress;
    }

    function setContractAddress(address[] memory contractaddressArray) public onlyOwner {
        _rolesCfgAddress = contractaddressArray[0];
        _storageAddress = contractaddressArray[1];
        _minerNFTPledgeAddress = contractaddressArray[2];
    }

    function addNode(string[] memory ipList, string[] memory serviceNameList, address[] memory accountList, uint256 gasFee) public {
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);
        require(HyperAGI_Roles_Cfg(_rolesCfgAddress).hasAdminRole(msg.sender), "not admin role");

        uint256[] memory idList = new uint256[](ipList.length);

        uint256 fee = gasFee / ipList.length;

        for (uint256 i = 0; i < ipList.length; i++) {
            string memory ipKey = ipList[i];

            if (storageAddress.getBool(ipKey)) {
                idList[i] = 0;

                continue;
            }

            uint256 id = storageAddress.getNextId();

            storageAddress.setBool(ipKey, true);

            storageAddress.setString(storageAddress.genKey("ip", id), ipList[i]);
            storageAddress.setString(storageAddress.genKey("serviceName", id), serviceNameList[i]);
            storageAddress.setAddress(storageAddress.genKey("account", id), accountList[i]);
            storageAddress.setBytes1(storageAddress.genKey("status", id), 0x00);
            storageAddress.setUint(storageAddress.genKey("fee", id), fee);

            idList[i] = id;
        }

        emit eveSave(idList, ipList, fee);
    }

    function getNode(uint256 id) public view returns (string[] memory stringArray, address, bytes1, uint256) {
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);

        string memory ip = storageAddress.getString(storageAddress.genKey("ip", id));

        require(bytes(ip).length > 0, string(abi.encodePacked("Error: nodeId is not found ", id.toString())));

        address account = storageAddress.getAddress(storageAddress.genKey("account", id));

        string[] memory stringArray = new string[](3);

        stringArray[0] = ip;
        stringArray[1] = storageAddress.getString(storageAddress.genKey("serviceName", id));

        bytes1 status = storageAddress.getBytes1(storageAddress.genKey("status", id));

        uint256 fee = storageAddress.getUint(storageAddress.genKey("fee", id));

        return (stringArray, account, status, fee);
    }

    function active(uint256 id) public payable {
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);

        HyperAGI_Miner_NFT_Pledge minerNFTPledgeAddress = HyperAGI_Miner_NFT_Pledge(_minerNFTPledgeAddress);

        address account = storageAddress.getAddress(storageAddress.genKey("account", id));

        uint256 fee = storageAddress.getUint(storageAddress.genKey("fee", id));

        require(msg.value == fee, "Invalid amount");

        require(msg.sender == account, "not the owner");

        bytes1 status = storageAddress.getBytes1(storageAddress.genKey("status", id));

        require(status == 0x00, "The node has been activated");

        minerNFTPledgeAddress.lock(account, 1);

        storageAddress.setBytes1(storageAddress.genKey("status", id), 0x01);

        uint256 index = storageAddress.setUintArray("ids", id);

        emit eveActive(id, index);
    }

    function getStatisticalIndex() public view returns (uint256, uint256) {
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);
        uint256 totalNum = storageAddress.getUint("totalNum");
        uint256 activeNum = storageAddress.getUint("activeNum");

        return (totalNum, activeNum);
    }

    function getAllNodeList() public view returns (uint256[] memory) {
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);
        uint256[] memory ids = storageAddress.getUintArray("ids");
        return ids;
    }

    function setStatisticalIndex(uint256 totalNum, uint256 activeNum) public {
        require(HyperAGI_Roles_Cfg(_rolesCfgAddress).hasAdminRole(msg.sender), "not admin role");
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);
        storageAddress.setUint("totalNum", totalNum);
        storageAddress.setUint("activeNum", activeNum);
    }

    function updateNodeIp(uint256 id, string memory ip) public {
        require(HyperAGI_Roles_Cfg(_rolesCfgAddress).hasAdminRole(msg.sender), "not admin role");
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);
        require(!storageAddress.getBool(ip), "The ip has been used");
        storageAddress.setString(storageAddress.genKey("ip", id), ip);
        storageAddress.setBool(ip, true);
    }

    function updateNodeIp(uint256 id, string memory ip, bool isWrite) public {
        revert("not used");
    }

    function forceUpdateNodeIp(uint256 id, string memory ip) public {
        require(HyperAGI_Roles_Cfg(_rolesCfgAddress).hasAdminRole(msg.sender), "not admin role");
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);
        storageAddress.setString(storageAddress.genKey("ip", id), ip);
        storageAddress.setBool(ip, true);
    }

    function forceUpdateServiceName(uint256 id, string memory serviceName) public {
        require(HyperAGI_Roles_Cfg(_rolesCfgAddress).hasAdminRole(msg.sender), "not admin role");
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);
        storageAddress.setString(storageAddress.genKey("serviceName", id), serviceName);
    }

    function updateStatus(uint256 id, bytes1 status) public {
        require(HyperAGI_Roles_Cfg(_rolesCfgAddress).hasAdminRole(msg.sender), "not admin role");
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);
        storageAddress.setBytes1(storageAddress.genKey("status", id), status);
    }
}
