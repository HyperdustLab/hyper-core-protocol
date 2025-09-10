// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../HyperAGI_Roles_Cfg.sol";
import "../HyperAGI_Storage.sol";

/**
 * @title HyperAGI_Agent_Wallet
 * @dev Manages Agent wallet allocation and airdrop functionality
 * Split from main contract to solve contract code length issues
 */
contract HyperAGI_Agent_Wallet is OwnableUpgradeable {
    
    address public _rolesCfgAddress;
    address public _storageAddress;
    
    uint256 public defaultTransferAmount; // Default transfer amount 1 ETH
    
    // Wallet address collection
    address[] public walletAddresses;
    mapping(address => bool) private _isWalletAllocated; // Record whether wallet has been allocated
    uint256 public nextWalletIndex; // Next wallet index to allocate
    
    // Wallet allocation related events
    event eveWalletAllocated(address walletAddress, uint256 transferAmount);
    event eveTransferAmountUpdated(uint256 newAmount);
    event eveWalletAdded(address walletAddress);
    
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
    
    
    function setContractAddress(address[] memory contractaddressArray) public onlyOwner {
        _rolesCfgAddress = contractaddressArray[0];
        _storageAddress = contractaddressArray[1];
    }
    
    // Set default transfer amount (admin only)
    function setDefaultTransferAmount(uint256 amount) public onlyAdmin {
        defaultTransferAmount = amount;
        emit eveTransferAmountUpdated(amount);
    }
    
    // Add wallet address to collection (admin only)
    function addWallet(address walletAddress) public onlyAdmin {
        require(walletAddress != address(0), "invalid wallet address");
        require(!_isWalletAllocated[walletAddress], "wallet already exists");
        
        walletAddresses.push(walletAddress);
        _isWalletAllocated[walletAddress] = false; // Initial state as unallocated
        emit eveWalletAdded(walletAddress);
    }
    
    // Batch add wallet addresses (admin only)
    function addWallets(address[] memory addresses) public onlyAdmin {
        for (uint256 i = 0; i < addresses.length; i++) {
            addWallet(addresses[i]);
        }
    }
    
    // Allocate an unallocated wallet address and transfer
    function allocateWallet() public onlyAdmin payable returns (address) {
        require(nextWalletIndex < walletAddresses.length, "no available wallets");
        
        address walletAddress = walletAddresses[nextWalletIndex];
        require(!_isWalletAllocated[walletAddress], "wallet already allocated");
        
        // Mark wallet as allocated
        _isWalletAllocated[walletAddress] = true;
        nextWalletIndex++;
        
        // If contract has sufficient balance, perform transfer
        if (address(this).balance >= defaultTransferAmount) {
            (bool success, ) = walletAddress.call{value: defaultTransferAmount}("");
            require(success, "transfer failed");
            emit eveWalletAllocated(walletAddress, defaultTransferAmount);
        }
        
        return walletAddress;
    }
    
    // Get total number of wallet addresses in collection
    function getWalletCount() public view returns (uint256) {
        return walletAddresses.length;
    }
    
    // Get number of allocated wallets
    function getAllocatedWalletCount() public view returns (uint256) {
        return nextWalletIndex;
    }
    
    // Get number of available wallets
    function getAvailableWalletCount() public view returns (uint256) {
        return walletAddresses.length - nextWalletIndex;
    }
    
    // Check if wallet has been allocated
    function checkWalletAllocated(address walletAddress) public view returns (bool) {
        return _isWalletAllocated[walletAddress];
    }
    
    // Allow contract to receive ETH
    receive() external payable {}
    
    // Withdraw contract balance (admin only)
    function withdraw() public onlyAdmin {
        payable(owner()).transfer(address(this).balance);
    }
}