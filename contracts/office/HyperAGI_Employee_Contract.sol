// SPDX-License-Identifier: MIT
/**
 * @title HyperAGI_Employee_Contract
 * @dev This is an upgradeable contract for managing employee employment contracts in the HyperAGI ecosystem
 * Features include contract creation, update, query, and deletion
 * Each contract has a unique auto-increment id identifier
 *
 * @dev Upgrade History:
 * - 2025-01-28: Initial implementation
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

import "../utils/StrUtil.sol";

import "../HyperAGI_Storage.sol";
import "../HyperAGI_Roles_Cfg.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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

    function getBytes32Uint(bytes32 key) public view virtual returns (uint256);
}

// Simplified Roles_Cfg abstract contract - only includes used functionality
abstract contract IHyperAGI_Roles_Cfg {
    function hasAdminRole(address account) public view virtual returns (bool);
}

// Simplified Office_Info abstract contract - only includes used functionality
abstract contract IHyperAGI_Office_Info {
    function getById(uint256 id) public view virtual returns (string memory officeName, address officeOwner, bytes32 spaceSid);
}

contract HyperAGI_Employee_Contract is OwnableUpgradeable {
    using Strings for *;
    using StrUtil for *;

    address public _storageAddress;

    address public _rolesCfgAddress;

    address public _officeInfoAddress;

    event eveSaveContract(uint256 id);

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

    function setStorageAddress(address storageAddress) public onlyOwner {
        _storageAddress = storageAddress;
    }

    function setRolesCfgAddress(address rolesCfgAddress) public onlyOwner {
        _rolesCfgAddress = rolesCfgAddress;
    }

    function setOfficeInfoAddress(address officeInfoAddress) public onlyOwner {
        _officeInfoAddress = officeInfoAddress;
    }

    function setContractAddress(address[] memory contractaddressArray) public onlyOwner {
        _storageAddress = contractaddressArray[0];
        _rolesCfgAddress = contractaddressArray[1];
        _officeInfoAddress = contractaddressArray[2];
    }

    /**
     * @dev Add a new employee contract
     * @param officeId The id of the office
     * @param employee The employee identifier (乙方) - bytes32
     * @param position The position/job title
     * @param skills The skills direction
     * @param salary The salary amount per week (in wei or token units)
     * @param settlementCycle The settlement cycle description
     * @param paymentMethod The payment method description
     * @param remarks Additional remarks
     * @return id The unique identifier (auto-increment ID) for the contract
     */
    function add(uint256 officeId, bytes32 employee, string memory position, string memory skills, uint256 salary, string memory settlementCycle, string memory paymentMethod, string memory remarks) public returns (uint256 id) {
        require(_officeInfoAddress != address(0), "office info not set");
        IHyperAGI_Office_Info officeInfo = IHyperAGI_Office_Info(_officeInfoAddress);
        (, address officeOwner, ) = officeInfo.getById(officeId);
        require(officeOwner != address(0), "office not found");
        require(officeOwner == msg.sender, "only office owner can create contract");

        IHyperAGI_Storage storageAddress = IHyperAGI_Storage(_storageAddress);
        id = storageAddress.getNextId();

        storageAddress.setUint(storageAddress.genKey("officeId", id), officeId);
        storageAddress.setBytes32(storageAddress.genKey("employee", id), employee);
        storageAddress.setString(storageAddress.genKey("position", id), position);
        storageAddress.setString(storageAddress.genKey("skills", id), skills);
        storageAddress.setUint(storageAddress.genKey("salary", id), salary);
        storageAddress.setString(storageAddress.genKey("settlementCycle", id), settlementCycle);
        storageAddress.setString(storageAddress.genKey("paymentMethod", id), paymentMethod);
        storageAddress.setString(storageAddress.genKey("remarks", id), remarks);
        storageAddress.setUint(storageAddress.genKey("signDate", id), block.timestamp);
        storageAddress.setAddress(storageAddress.genKey("contractCreator", id), msg.sender);
        storageAddress.setUint(storageAddress.genKey("contractStatus", id), 0); // 0 = 正常, 1 = 解雇

        emit eveSaveContract(id);

        return id;
    }

    /**
     * @dev Get contract information by id
     * @param id The unique identifier (auto-increment ID) of the contract
     * @return officeId The id of the office
     * @return employee The employee identifier (bytes32)
     * @return position The position/job title
     * @return skills The skills direction
     * @return salary The salary amount per week
     * @return settlementCycle The settlement cycle description
     * @return paymentMethod The payment method description
     * @return remarks Additional remarks
     * @return signDate The signing date (timestamp, automatically set to block timestamp when contract is created/updated)
     * @return contractCreator The address who created the contract
     * @return contractStatus The contract status (0 = 正常, 1 = 解雇)
     */
    function getById(
        uint256 id
    ) public view returns (uint256 officeId, bytes32 employee, string memory position, string memory skills, uint256 salary, string memory settlementCycle, string memory paymentMethod, string memory remarks, uint256 signDate, address contractCreator, uint256 contractStatus) {
        IHyperAGI_Storage storageAddress = IHyperAGI_Storage(_storageAddress);

        require(id > 0, "invalid id");

        officeId = storageAddress.getUint(storageAddress.genKey("officeId", id));
        employee = storageAddress.getBytes32(storageAddress.genKey("employee", id));
        position = storageAddress.getString(storageAddress.genKey("position", id));
        skills = storageAddress.getString(storageAddress.genKey("skills", id));
        salary = storageAddress.getUint(storageAddress.genKey("salary", id));
        settlementCycle = storageAddress.getString(storageAddress.genKey("settlementCycle", id));
        paymentMethod = storageAddress.getString(storageAddress.genKey("paymentMethod", id));
        remarks = storageAddress.getString(storageAddress.genKey("remarks", id));
        signDate = storageAddress.getUint(storageAddress.genKey("signDate", id));
        contractCreator = storageAddress.getAddress(storageAddress.genKey("contractCreator", id));
        contractStatus = storageAddress.getUint(storageAddress.genKey("contractStatus", id));

        return (officeId, employee, position, skills, salary, settlementCycle, paymentMethod, remarks, signDate, contractCreator, contractStatus);
    }

    /**
     * @dev Terminate an employee contract (解雇)
     * @param id The unique identifier (auto-increment ID) of the contract
     */
    function terminate(uint256 id) public {
        IHyperAGI_Storage storageAddress = IHyperAGI_Storage(_storageAddress);

        require(id > 0, "invalid id");

        address contractCreator = storageAddress.getAddress(storageAddress.genKey("contractCreator", id));
        require(contractCreator != address(0), "contract not found");

        uint256 contractStatus = storageAddress.getUint(storageAddress.genKey("contractStatus", id));
        require(contractStatus == 0, "contract already terminated");

        uint256 officeId = storageAddress.getUint(storageAddress.genKey("officeId", id));
        require(_officeInfoAddress != address(0), "office info not set");
        IHyperAGI_Office_Info officeInfo = IHyperAGI_Office_Info(_officeInfoAddress);
        (, address officeOwner, ) = officeInfo.getById(officeId);
        require(officeOwner != address(0), "office not found");
        require(officeOwner == msg.sender, "only office owner can terminate contract");

        storageAddress.setUint(storageAddress.genKey("contractStatus", id), 1); // 1 = 解雇

        emit eveSaveContract(id);
    }

    /**
     * @dev Check if a contract exists by id
     * @param id The unique identifier (auto-increment ID) of the contract
     * @return exists Whether the contract exists
     */
    function existsById(uint256 id) public view returns (bool) {
        if (id == 0) {
            return false;
        }
        IHyperAGI_Storage storageAddress = IHyperAGI_Storage(_storageAddress);
        address contractCreator = storageAddress.getAddress(storageAddress.genKey("contractCreator", id));
        return contractCreator != address(0);
    }

    /**
     * @dev Internal function to check if an address has admin role
     * @param account The address to check
     * @return Whether the address has admin role
     */
    function _isAdmin(address account) private view returns (bool) {
        if (_rolesCfgAddress == address(0)) {
            return account == owner();
        }
        IHyperAGI_Roles_Cfg rolesCfg = IHyperAGI_Roles_Cfg(_rolesCfgAddress);
        return rolesCfg.hasAdminRole(account) || account == owner();
    }
}
