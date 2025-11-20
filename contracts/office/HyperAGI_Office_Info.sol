// SPDX-License-Identifier: MIT
/**
 * @title HyperAGI_Office_Info
 * @dev This is an upgradeable contract for managing office information in the HyperAGI ecosystem
 * Features include office creation, update, query, and deletion
 * Each office has a unique auto-increment id identifier
 *
 * @dev Upgrade History:
 * - 2025-01-XX: Initial implementation
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

contract HyperAGI_Office_Info is OwnableUpgradeable {
    using Strings for *;
    using StrUtil for *;

    address public _storageAddress;

    address public _rolesCfgAddress;

    event eveSaveOffice(uint256 id);
    event eveDeleteOffice(uint256 id);

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

    function setContractAddress(address[] memory contractaddressArray) public onlyOwner {
        _storageAddress = contractaddressArray[0];
        _rolesCfgAddress = contractaddressArray[1];
    }

    /**
     * @dev Add a new office information
     * @param officeName The name of the office
     * @param spaceSid The space sid (bytes32) associated with the office
     * @return id The unique identifier (auto-increment ID) for the office
     */
    function add(string memory officeName, bytes32 spaceSid) public returns (uint256 id) {
        IHyperAGI_Storage storageAddress = IHyperAGI_Storage(_storageAddress);
        id = storageAddress.getNextId();

        storageAddress.setString(storageAddress.genKey("officeName", id), officeName);
        storageAddress.setAddress(storageAddress.genKey("officeOwner", id), msg.sender);
        storageAddress.setBytes32(storageAddress.genKey("spaceSid", id), spaceSid);

        emit eveSaveOffice(id);

        return id;
    }

    /**
     * @dev Get office information by id
     * @param id The unique identifier (auto-increment ID) of the office
     * @return officeName The name of the office
     * @return officeOwner The owner address of the office
     * @return spaceSid The space sid associated with the office
     */
    function getById(uint256 id) public view returns (string memory officeName, address officeOwner, bytes32 spaceSid) {
        IHyperAGI_Storage storageAddress = IHyperAGI_Storage(_storageAddress);

        require(id > 0, "invalid id");

        officeName = storageAddress.getString(storageAddress.genKey("officeName", id));
        officeOwner = storageAddress.getAddress(storageAddress.genKey("officeOwner", id));
        spaceSid = storageAddress.getBytes32(storageAddress.genKey("spaceSid", id));
    }

    /**
     * @dev Update office information by id
     * @param id The unique identifier (auto-increment ID) of the office
     * @param officeName The new name of the office
     * @param officeOwner The new owner address of the office
     * @param spaceSid The new space sid associated with the office
     */
    function updateById(uint256 id, string memory officeName, address officeOwner, bytes32 spaceSid) public {
        IHyperAGI_Storage storageAddress = IHyperAGI_Storage(_storageAddress);

        require(id > 0, "invalid id");

        address currentOwner = storageAddress.getAddress(storageAddress.genKey("officeOwner", id));
        require(currentOwner != address(0), "not found");

        require(currentOwner == msg.sender || _isAdmin(msg.sender), "You don't have permission to operate");

        storageAddress.setString(storageAddress.genKey("officeName", id), officeName);
        storageAddress.setAddress(storageAddress.genKey("officeOwner", id), officeOwner);
        storageAddress.setBytes32(storageAddress.genKey("spaceSid", id), spaceSid);

        emit eveSaveOffice(id);
    }

    /**
     * @dev Delete office information by id
     * @param id The unique identifier (auto-increment ID) of the office
     */
    function delById(uint256 id) public {
        IHyperAGI_Storage storageAddress = IHyperAGI_Storage(_storageAddress);

        require(id > 0, "invalid id");

        address currentOwner = storageAddress.getAddress(storageAddress.genKey("officeOwner", id));
        require(currentOwner != address(0), "not found");

        require(currentOwner == msg.sender || _isAdmin(msg.sender), "You don't have permission to operate");

        storageAddress.setString(storageAddress.genKey("officeName", id), "");
        storageAddress.setAddress(storageAddress.genKey("officeOwner", id), address(0));
        storageAddress.setBytes32(storageAddress.genKey("spaceSid", id), bytes32(0));

        emit eveDeleteOffice(id);
    }

    /**
     * @dev Check if an office exists by id
     * @param id The unique identifier (auto-increment ID) of the office
     * @return exists Whether the office exists
     */
    function existsById(uint256 id) public view returns (bool) {
        if (id == 0) {
            return false;
        }
        IHyperAGI_Storage storageAddress = IHyperAGI_Storage(_storageAddress);
        address officeOwner = storageAddress.getAddress(storageAddress.genKey("officeOwner", id));
        return officeOwner != address(0);
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
