# HyperAGI Agent Contract Split Documentation

## Overview

Due to the excessive length of the original `HyperAGI_Agent.sol` contract code, deployment was not possible. Therefore, wallet-related functionality has been split into a separate contract.

## Contract Structure

### 1. HyperAGI_Agent.sol (Main Contract)

- **Functionality**: Core Agent functionality including creation, updates, queries, etc.
- **Main Features**:
  - Agent mint, update, get operations
  - Energy recharge (rechargeEnergy)
  - Time cycle management
  - Agent count management
  - Wallet allocation through wallet contract reference

### 2. HyperAGI_Agent_Wallet.sol (Wallet Management Contract)

- **Functionality**: Specialized management of Agent wallet allocation and airdrops
- **Main Features**:
  - Dynamic generation of Agent wallet addresses
  - Wallet allocation logic
  - Airdrop transfers
  - Wallet status queries

## Major Changes

### Functionality Removed from Main Contract

- Wallet address pool related variables and mappings
- Wallet pool management related functions
- `receive()` function

### New Integrations

- Added `_agentWalletAddress` variable
- Added `setAgentWalletAddress()` function
- Updated `setContractAddress()` function to support wallet contract address
- Updated `mintV3()` function to allocate wallets through wallet contract
- Updated `getAgentWallet()` function to query through wallet contract
- Updated `getAgentV3()` function to get wallet address through wallet contract

## Deployment and Usage

### Deployment Order

1. Deploy `HyperAGI_Agent_Wallet` contract first
2. Deploy `HyperAGI_Agent` contract
3. Set wallet contract address to main contract
4. Initialize wallet contract

### Usage Example

```typescript
// 1. Set default transfer amount
await agentWallet.setDefaultTransferAmount(ethers.parseEther('1.0'))

// 2. Create Agent (will automatically generate and allocate wallet address and transfer)
await agent.mintV3(tokenId, strParams, { value: ethers.parseEther('1.0') })

// 3. Query Agent's wallet address
const walletAddress = await agent.getAgentWallet(sid)
```

## Advantages

1. **Code Separation**: Main contract code is more concise and easier to maintain
2. **Single Responsibility**: Wallet management functionality is independent and easier to upgrade
3. **Successful Deployment**: Resolves the issue of contract code being too long to deploy
4. **Backward Compatibility**: Maintains original API interface unchanged
5. **Upgrade Friendly**: Wallet functionality can be upgraded independently without affecting main contract

## Notes

- Wallet contract must be deployed and set to main contract first
- Transfer amount needs to be set in advance
- Main contract calls wallet contract functionality through interface
- Each Agent automatically generates a unique wallet address without needing to prepare address pool in advance
