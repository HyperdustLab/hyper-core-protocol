// SPDX-License-Identifier: MIT
/**
 * @title HyperAGI_Office_TaskReward
 * @dev Manage task reward settlements within an office context.
 *
 * Features:
 * - Create task rewards tied to employee contracts
 * - Enforce office owner authorization
 * - Automatically transfer reward payments to the agent wallet
 *
 * Upgrade History:
 * - 2025-11-20: Initial implementation
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../utils/StrUtil.sol";
import "../HyperAGI_Storage.sol";
import "../HyperAGI_Roles_Cfg.sol";

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

    function getBytes32(string memory key) public view virtual returns (bytes32);

    function setAddress(string memory key, address value) public virtual;

    function getAddress(string memory key) public view virtual returns (address);
}

// Simplified Roles_Cfg abstract contract - only includes used functionality
abstract contract IHyperAGI_Roles_Cfg {
    function hasAdminRole(address account) public view virtual returns (bool);
}

// Simplified Office_Info abstract contract - only includes used functionality
abstract contract IHyperAGI_Office_Info {
    function getById(uint256 id) public view virtual returns (string memory officeName, address officeOwner, bytes32 spaceSid);
}

// Simplified Employee_Contract abstract contract - only includes used functionality
abstract contract IHyperAGI_Employee_Contract {
    function getById(
        uint256 id
    ) public view virtual returns (uint256 officeId, bytes32 employee, string memory position, string memory skills, uint256 salary, string memory settlementCycle, string memory paymentMethod, string memory remarks, uint256 signDate, address contractCreator, uint256 contractStatus);
}

// Simplified Agent abstract contract - only includes used functionality
abstract contract IHyperAGI_Agent {
    function getAgentWallet(bytes32 sid) public view virtual returns (address);
}

contract HyperAGI_Office_TaskReward is OwnableUpgradeable {
    using Strings for *;
    using StrUtil for *;

    struct TaskRewardInput {
        uint256 officeId;
        bytes32 sid;
        uint256 contractId;
        string taskUniqueId;
        string taskId;
        string taskName;
        string summary;
        string deadline;
        string status;
        string taskOutput;
        string exp;
    }

    address public _storageAddress;

    address public _rolesCfgAddress;

    address public _officeInfoAddress;

    address public _employeeContractAddress;

    address public _agentContractAddress;

    event eveSaveTaskReward(uint256 id);

    function initialize(address onlyOwner) public initializer {
        __Ownable_init(onlyOwner);
    }

    function setStorageAddress(address storageAddress) public onlyOwner {
        _storageAddress = storageAddress;
    }

    function setRolesCfgAddress(address rolesCfgAddress) public onlyOwner {
        _rolesCfgAddress = rolesCfgAddress;
    }

    function setOfficeInfoAddress(address officeInfoAddress) public onlyOwner {
        _officeInfoAddress = officeInfoAddress;
    }

    function setEmployeeContractAddress(address employeeContractAddress) public onlyOwner {
        _employeeContractAddress = employeeContractAddress;
    }

    function setAgentContractAddress(address agentContractAddress) public onlyOwner {
        _agentContractAddress = agentContractAddress;
    }

    function setContractAddress(address[] memory contractaddressArray) public onlyOwner {
        require(contractaddressArray.length >= 5, "invalid config");
        _storageAddress = contractaddressArray[0];
        _rolesCfgAddress = contractaddressArray[1];
        _officeInfoAddress = contractaddressArray[2];
        _employeeContractAddress = contractaddressArray[3];
        _agentContractAddress = contractaddressArray[4];
    }

    /**
     * @dev Create a task reward entry and instantly transfer the reward to the agent wallet.
     */
    function createTaskReward(
        uint256 officeId,
        bytes32 sid,
        uint256 contractId,
        string memory taskUniqueId,
        string memory taskId,
        string memory taskName,
        string memory summary,
        string memory deadline,
        string memory status,
        string memory taskOutput,
        string memory exp
    ) public payable returns (uint256 id) {
        TaskRewardInput memory input = TaskRewardInput({officeId: officeId, sid: sid, contractId: contractId, taskUniqueId: taskUniqueId, taskId: taskId, taskName: taskName, summary: summary, deadline: deadline, status: status, taskOutput: taskOutput, exp: exp});
        return _createTaskReward(input);
    }

    function _createTaskReward(TaskRewardInput memory input) internal returns (uint256 id) {
        require(_storageAddress != address(0), "storage not set");
        require(_officeInfoAddress != address(0), "office info not set");
        require(_employeeContractAddress != address(0), "employee contract not set");
        require(_agentContractAddress != address(0), "agent contract not set");
        require(bytes(input.taskUniqueId).length > 0, "task unique id required");
        _validateOfficeOwner(input.officeId);
        uint256 salary = _validateContract(input);
        require(msg.value == salary, "invalid payment amount");

        address recipient = _getAgentWallet(input.sid);

        IHyperAGI_Storage storageAddress = IHyperAGI_Storage(_storageAddress);
        string memory uniqueKey = string(abi.encodePacked("taskRewardUnique_", input.taskUniqueId));
        require(storageAddress.getUint(uniqueKey) == 0, "task unique id exists");

        Address.sendValue(payable(recipient), salary);

        id = storageAddress.getNextId();

        storageAddress.setBytes32(storageAddress.genKey("sid", id), input.sid);
        storageAddress.setUint(storageAddress.genKey("officeId", id), input.officeId);
        storageAddress.setUint(storageAddress.genKey("contractId", id), input.contractId);
        storageAddress.setString(storageAddress.genKey("taskUniqueId", id), input.taskUniqueId);
        storageAddress.setString(storageAddress.genKey("taskId", id), input.taskId);
        storageAddress.setString(storageAddress.genKey("taskName", id), input.taskName);
        storageAddress.setString(storageAddress.genKey("summary", id), input.summary);
        storageAddress.setString(storageAddress.genKey("deadline", id), input.deadline);
        storageAddress.setString(storageAddress.genKey("status", id), input.status);
        storageAddress.setString(storageAddress.genKey("taskOutput", id), input.taskOutput);
        storageAddress.setString(storageAddress.genKey("exp", id), input.exp);
        storageAddress.setUint(storageAddress.genKey("createTime", id), block.timestamp);
        storageAddress.setUint(storageAddress.genKey("updateTime", id), block.timestamp);
        storageAddress.setUint(storageAddress.genKey("rewardAmount", id), salary);
        storageAddress.setAddress(storageAddress.genKey("recipient", id), recipient);
        storageAddress.setUint(uniqueKey, id);

        emit eveSaveTaskReward(id);

        return id;
    }

    function _validateOfficeOwner(uint256 officeId) internal view {
        IHyperAGI_Office_Info officeInfo = IHyperAGI_Office_Info(_officeInfoAddress);
        (, address officeOwner, ) = officeInfo.getById(officeId);
        require(officeOwner != address(0), "office not found");
        require(officeOwner == msg.sender, "only office owner can create reward");
    }

    function _validateContract(TaskRewardInput memory input) internal view returns (uint256 salary) {
        IHyperAGI_Employee_Contract employeeContract = IHyperAGI_Employee_Contract(_employeeContractAddress);
        (uint256 contractOfficeId, bytes32 contractEmployee, , , uint256 reward, , , , , , uint256 contractStatus) = employeeContract.getById(input.contractId);

        require(contractStatus == 0, "contract inactive");
        require(contractOfficeId == input.officeId, "office mismatch");
        require(contractEmployee == input.sid, "sid mismatch");
        require(reward > 0, "invalid reward amount");

        return reward;
    }

    function _getAgentWallet(bytes32 sid) internal view returns (address) {
        IHyperAGI_Agent agentContract = IHyperAGI_Agent(_agentContractAddress);
        address recipient = agentContract.getAgentWallet(sid);
        require(recipient != address(0), "agent wallet not found");
        return recipient;
    }

    /**
     * @dev Retrieve a task reward entry.
     */
    /**
     * 返回值说明：
     * - uintFields: [0]=officeId, [1]=contractId, [2]=createTime, [3]=updateTime, [4]=rewardAmount
     * - stringFields: [0]=taskUniqueId, [1]=taskId, [2]=taskName, [3]=summary, [4]=deadline, [5]=status, [6]=taskOutput, [7]=exp
     */
    function getTaskReward(uint256 id) public view returns (bytes32 sid, uint256[] memory uintFields, string[] memory stringFields, address recipient) {
        require(_storageAddress != address(0), "storage not set");
        require(id > 0, "invalid id");

        IHyperAGI_Storage storageAddress = IHyperAGI_Storage(_storageAddress);

        sid = storageAddress.getBytes32(storageAddress.genKey("sid", id));
        require(sid != bytes32(0), "task reward not found");

        uintFields = new uint256[](5);
        uintFields[0] = storageAddress.getUint(storageAddress.genKey("officeId", id));
        uintFields[1] = storageAddress.getUint(storageAddress.genKey("contractId", id));
        uintFields[2] = storageAddress.getUint(storageAddress.genKey("createTime", id));
        uintFields[3] = storageAddress.getUint(storageAddress.genKey("updateTime", id));
        uintFields[4] = storageAddress.getUint(storageAddress.genKey("rewardAmount", id));

        stringFields = new string[](8);
        stringFields[0] = storageAddress.getString(storageAddress.genKey("taskUniqueId", id));
        stringFields[1] = storageAddress.getString(storageAddress.genKey("taskId", id));
        stringFields[2] = storageAddress.getString(storageAddress.genKey("taskName", id));
        stringFields[3] = storageAddress.getString(storageAddress.genKey("summary", id));
        stringFields[4] = storageAddress.getString(storageAddress.genKey("deadline", id));
        stringFields[5] = storageAddress.getString(storageAddress.genKey("status", id));
        stringFields[6] = storageAddress.getString(storageAddress.genKey("taskOutput", id));
        stringFields[7] = storageAddress.getString(storageAddress.genKey("exp", id));

        recipient = storageAddress.getAddress(storageAddress.genKey("recipient", id));

        return (sid, uintFields, stringFields, recipient);
    }
}
