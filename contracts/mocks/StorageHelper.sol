// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../HyperAGI_Storage.sol";

/**
 * @title StorageHelper
 * @dev Helper contract to call Storage methods for testing purposes
 */
contract StorageHelper {
    using Strings for uint256;
    
    HyperAGI_Storage public storageContract;

    constructor(address _storageAddress) {
        storageContract = HyperAGI_Storage(_storageAddress);
    }

    function getNextId() public returns (uint256) {
        return storageContract.getNextId();
    }

    function setUint(string memory key, uint256 value) public {
        storageContract.setUint(key, value);
    }

    function setString(string memory key, string memory value) public {
        storageContract.setString(key, value);
    }

    function setBytes32(string memory key, bytes32 value) public {
        storageContract.setBytes32(key, value);
    }

    function setAddress(string memory key, address value) public {
        storageContract.setAddress(key, value);
    }

    function setBytes32Uint(bytes32 key, uint256 value) public {
        storageContract.setBytes32Uint(key, value);
    }

    function genKey(string memory prefix, uint256 id) public pure returns (string memory) {
        return string(abi.encodePacked(prefix, "_", id.toString()));
    }
}

