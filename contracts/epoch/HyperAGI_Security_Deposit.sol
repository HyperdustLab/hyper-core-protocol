pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../utils/StrUtil.sol";

import "../HyperAGI_Storage.sol";

import "../node/HyperAGI_Node_Mgr.sol";

import "../HyperAGI_Roles_Cfg.sol";

contract HyperAGI_Security_Deposit is OwnableUpgradeable {
    using Strings for *;
    using StrUtil for *;

    address public _rolesCfgAddress;
    address public _storageAddress;
    address public _nodeMgrAddress;
    uint32 public _withdrawalInterval;

    function initialize(address onlyOwner) public initializer {
        __Ownable_init(onlyOwner);
        _withdrawalInterval = 30 days;
    }

    event eveSave(uint256 nodeId, uint256 totalSecurityAmount, uint256 amount);
    event eveUpdateBlockchainStatus(uint256 nodeId, bytes1 status, uint256 withdrawalTime);

    function setRolesCfgAddress(address rolesCfgAddress) public onlyOwner {
        _rolesCfgAddress = rolesCfgAddress;
    }

    function setStorageAddress(address storageAddress) public onlyOwner {
        _storageAddress = storageAddress;
    }

    function setNodeMgrAddress(address nodeMgrAddress) public onlyOwner {
        _nodeMgrAddress = nodeMgrAddress;
    }

    function setWithdrawalInterval(uint32 withdrawalInterval) public onlyOwner {
        _withdrawalInterval = withdrawalInterval;
    }

    function setContractAddress(address[] memory contractaddressArray) public onlyOwner {
        _rolesCfgAddress = contractaddressArray[0];
        _storageAddress = contractaddressArray[1];
        _nodeMgrAddress = contractaddressArray[2];
    }

    function addSecurityDeposit(uint256 nodeId, uint256 amount) public payable {
        require(HyperAGI_Roles_Cfg(_rolesCfgAddress).hasAdminRole(msg.sender), "not admin role");

        require(amount == msg.value, "amount error");

        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);

        HyperAGI_Node_Mgr nodeMgrAddress = HyperAGI_Node_Mgr(_nodeMgrAddress);

        (, address incomeAddress, , ) = nodeMgrAddress.getNode(nodeId);

        string memory key = nodeId.toString();

        uint256 _amount = storageAddress.getUint(key) + amount;

        storageAddress.setUint(key, _amount);

        storageAddress.setUint(incomeAddress.toHexString(), storageAddress.getUint(incomeAddress.toHexString()) + amount);

        string memory incomeAddressIndexKey = incomeAddress.toHexString().toSlice().concat("_index".toSlice());

        uint256 incomeAddressIndex = storageAddress.getUint(incomeAddressIndexKey);

        if (incomeAddressIndex == 0) {
            storageAddress.setAddressArray("incomeAddressList", incomeAddress);

            uint256 incomeAddressListTotal = storageAddress.getUint("incomeAddressListTotal");

            storageAddress.setUint(incomeAddressIndexKey, incomeAddressListTotal);

            incomeAddressListTotal++;

            storageAddress.setUint("incomeAddressListTotal", incomeAddressListTotal + 1);
        }

        emit eveSave(nodeId, _amount, amount);
    }

    function applyWithdrawal(uint256 nodeId) public {
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);
        HyperAGI_Node_Mgr nodeMgrAddress = HyperAGI_Node_Mgr(_nodeMgrAddress);

        (, address incomeAddress, , ) = nodeMgrAddress.getNode(nodeId);

        require(incomeAddress == msg.sender, "not income address");

        string memory key = storageAddress.genKey("applyWithdrawal_", nodeId);

        uint256 time = storageAddress.getUint(key);

        require(time == 0, "already apply");

        storageAddress.setUint(key, block.timestamp);

        nodeMgrAddress.updateStatus(nodeId, 0x02);

        emit eveUpdateBlockchainStatus(nodeId, 0x02, block.timestamp + _withdrawalInterval);
    }

    function cancelWithdrawal(uint256 nodeId) public {
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);

        HyperAGI_Node_Mgr nodeMgrAddress = HyperAGI_Node_Mgr(_nodeMgrAddress);
        (, address incomeAddress, , ) = nodeMgrAddress.getNode(nodeId);

        require(incomeAddress == msg.sender, "not income address");

        string memory key = storageAddress.genKey("applyWithdrawal_", nodeId);

        storageAddress.setUint(key, 0);

        nodeMgrAddress.updateStatus(nodeId, 0x01);

        emit eveUpdateBlockchainStatus(nodeId, 0x01, 0);
    }

    function withdrawal(uint256 nodeId) public {
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);

        HyperAGI_Node_Mgr nodeMgrAddress = HyperAGI_Node_Mgr(_nodeMgrAddress);

        (, address incomeAddress, , ) = nodeMgrAddress.getNode(nodeId);

        require(incomeAddress == msg.sender || HyperAGI_Roles_Cfg(_rolesCfgAddress).hasAdminRole(msg.sender), "not income address");

        uint256 amount = storageAddress.getUint(nodeId.toString());

        require(amount > 0, "There is no amount to withdraw");

        string memory applyWithdrawalKey = storageAddress.genKey("applyWithdrawal_", nodeId);

        uint256 applyWithdrawalTime = storageAddress.getUint(applyWithdrawalKey);

        require(applyWithdrawalTime > 0 && applyWithdrawalTime + _withdrawalInterval < block.timestamp, "not apply withdrawal or not reach withdrawal time");

        storageAddress.setUint(applyWithdrawalKey, 0);

        storageAddress.setUint(nodeId.toString(), 0);

        string memory incomeAddressKey = incomeAddress.toHexString();

        uint256 incomeAddressAmount = storageAddress.getUint(incomeAddressKey);

        incomeAddressAmount -= amount;

        storageAddress.setUint(incomeAddressKey, incomeAddressAmount);

        if (incomeAddressAmount == 0) {
            uint256 incomeAddressListTotal = storageAddress.getAddressArray("incomeAddressList").length;

            incomeAddressListTotal--;

            string memory incomeAddressIndexKey = incomeAddress.toHexString().toSlice().concat("_index".toSlice());

            uint256 incomeAddressIndex = storageAddress.getUint(incomeAddressIndexKey);

            if (incomeAddressListTotal > 0 && incomeAddressIndex < incomeAddressListTotal) {
                storageAddress.removeAddressArray("incomeAddressList", incomeAddressIndex);

                address newAddress = storageAddress.getAddressArray("incomeAddressList")[incomeAddressIndex];

                storageAddress.setAddress(incomeAddressIndexKey, newAddress);
            }

            storageAddress.setUint("incomeAddressListTotal", incomeAddressListTotal);
        }

        transferETH(payable(incomeAddress), amount);

        nodeMgrAddress.updateStatus(nodeId, 0x03);

        emit eveUpdateBlockchainStatus(nodeId, 0x03, 0);
    }

    function getNodeSecurityDeposit(uint256 nodeId) public view returns (uint256) {
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);
        return storageAddress.getUint(nodeId.toString());
    }

    function getIncomeAddressList() public view returns (address[] memory) {
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);

        return storageAddress.getAddressArray("incomeAddressList");
    }

    function getSecurityDeposit(address account) public view returns (uint256) {
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);

        return storageAddress.getUint(account.toHexString());
    }

    function transferETH(address payable recipient, uint256 amount) private {
        require(address(this).balance >= amount, "Insufficient balance in contract");
        recipient.transfer(amount);
    }
}
