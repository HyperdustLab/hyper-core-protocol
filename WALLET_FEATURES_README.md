# HyperAGI_Agent Wallet Address Pool Feature Description

## Feature Overview

HyperAGI_Agent contract has added wallet address pool functionality, supporting automatic allocation of unique wallet addresses for each Agent and ETH transfer during allocation.

## New Features

### 1. Wallet Address Pool Management

#### Add Wallet Addresses to Address Pool

```solidity
function addWalletToPool(address[] memory walletAddresses) public onlyAdmin
```

- **Function**: Add new wallet addresses to wallet address pool
- **Permission**: Only admin role can call
- **Parameters**: `walletAddresses` - Array of wallet addresses to add
- **Event**: `eveWalletAdded(address walletAddress)`

#### View Wallet Address Pool Status

```solidity
function getWalletPoolInfo() public view returns (uint256 totalWallets, uint256 allocatedWallets, uint256 availableWallets)
```

- **Return Values**:
  - `totalWallets`: Total wallet count in address pool
  - `allocatedWallets`: Number of allocated wallets
  - `availableWallets`: Number of available wallets

#### Get Wallet Address Pool

```solidity
function getWalletPool() public view returns (address[] memory)
```

- **Return Value**: All wallet addresses in address pool

#### Check if Wallet is Allocated

```solidity
function isWalletAllocated(address wallet) public view returns (bool)
```

- **Function**: Check if specified wallet address has been allocated

### 2. Transfer Amount Settings

#### Set Default Transfer Amount

```solidity
function setDefaultTransferAmount(uint256 amount) public onlyAdmin
```

- **Function**: Set default transfer amount for mintV3 to allocated wallet
- **Permission**: Only admin role can call
- **Default Value**: 1 ETH
- **Event**: `eveTransferAmountUpdated(uint256 newAmount)`

### 3. Enhanced mintV3 Functionality

#### Automatic Wallet Allocation and Transfer

```solidity
function mintV3(uint256 tokenId, string[] memory strParams) public payable
```

- **New Features**:
  - Automatically allocate an unused wallet address from wallet address pool
  - Associate allocated wallet address with Agent and store it
  - Transfer specified amount of ETH to allocated wallet address
- **Event**: `eveWalletAllocated(bytes32 sid, address walletAddress, uint256 transferAmount)`

### 4. Agent Wallet Address Query

#### Get Agent Wallet Address

```solidity
function getAgentWallet(bytes32 sid) public view returns (address)
```

- **Function**: Get Agent's associated wallet address based on Agent's SID

#### Get Complete Agent Information (Including Wallet Address)

```solidity
function getAgentV3(bytes32 sid) public view returns (uint256, string memory, string memory, string memory, string memory, uint256, address)
```

- **Return Value**: Complete Agent information including wallet address

## Usage Process

### 1. Initialize Wallet Address Pool

```javascript
// Admin adds wallet addresses to address pool
const walletAddresses = ['0x1234567890123456789012345678901234567890', '0x2345678901234567890123456789012345678901', '0x3456789012345678901234567890123456789012']
await agent.addWalletToPool(walletAddresses)
```

### 2. Set Transfer Amount

```javascript
// Set transfer amount to 0.5 ETH
await agent.setDefaultTransferAmount(ethers.parseEther('0.5'))
```

### 3. Send ETH to Contract

```javascript
// Send ETH to contract for transfers
await deployer.sendTransaction({
  to: agentAddress,
  value: ethers.parseEther('10.0'),
})
```

### 4. Create Agent (Automatic Wallet Allocation)

```javascript
const strParams = ['avatar_url', 'Agent Name', 'Agent Description', 'Welcome Message']

// mintV3 will automatically allocate wallet address and transfer
const tx = await agent.mintV3(1, strParams)
const receipt = await tx.wait()

// Listen for wallet allocation event
const walletAllocatedEvent = receipt.logs.find(log => {
  const parsed = agent.interface.parseLog(log)
  return parsed?.name === 'eveWalletAllocated'
})
```

### 5. Query Agent Wallet Address

```javascript
// Get Agent wallet address
const agentWallet = await agent.getAgentWallet(agentSid)
console.log('Agent wallet address:', agentWallet)

// Get complete Agent information
const agentInfo = await agent.getAgentV3(agentSid)
console.log('Complete Agent information:', agentInfo)
```

## Security Features

1. **Permission Control**: Only admin role can add wallet addresses and set transfer amounts
2. **Duplicate Allocation Prevention**: Allocated wallet addresses will not be allocated again
3. **Address Validation**: Validates address validity when adding wallet addresses
4. **Transfer Security**: Uses `call` method for secure ETH transfers

## Event Descriptions

- `eveWalletAllocated`: Wallet allocation event, includes SID, wallet address and transfer amount
- `eveWalletAdded`: Wallet address added to address pool event
- `eveTransferAmountUpdated`: Transfer amount update event

## Notes

1. Ensure contract has sufficient ETH for transfers
2. Cannot create Agent when wallet address pool is empty
3. Need to add new wallet addresses when all wallet addresses are allocated
4. Transfer amount should not exceed contract balance
5. Recommend regularly checking available wallet count in address pool

## Testing

Run test script to verify functionality:

```bash
npx hardhat run scripts/HyperAGI_Agent_Wallet_Test.ts --network localhost
```
