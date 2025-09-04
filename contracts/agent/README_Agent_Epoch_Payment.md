# HyperAGI Agent Epoch Payment Contract

## Overview

`HyperAGI_Agent_Epoch_Payment` is an upgradeable smart contract for handling Agent Epoch fee payments. After users pay the fee, the contract automatically updates the corresponding Agent's time period.

## Main Features

### 1. Pay Epoch Fee

- **Function**: `payEpochFee(bytes32 sid)`
- **Fee**: Fixed 0.001 ETH
- **Functionality**: Automatically updates Agent's time period after successful payment (current time + 6.4 minutes)

### 2. Admin Payment

- **Function**: `adminPayEpochFee(bytes32 sid)`
- **Permission**: Admin only
- **Functionality**: Admin can update Agent's time period for free

### 3. Contract Management

- **Upgradeable**: Uses OpenZeppelin's Initializable + OwnableUpgradeable upgrade mode (consistent with HyperAGI_Agent.sol)
- **Access Control**: Role-based access control
- **ETH Management**: Supports withdrawing ETH from contract

## Contract Parameters

- **Payment Fee**: 0.001 ETH (fixed in method, can be modified during upgrade)
- **epochDuration**: 384 seconds (6.4 minutes, can be modified during upgrade)

## Events

```solidity
event EpochPaymentCompleted(bytes32 indexed sid, uint256 startTime, uint256 endTime, uint256 paymentAmount, address payer);
```

## Deployment Steps

### 1. Compile Contract

```bash
npx hardhat compile
```

### 2. Deploy Contract

```bash
npx hardhat run scripts/HyperAGI_Agent_Epoch_Payment.ts --network <network_name>
```

### 3. Initialize Contract

The contract will automatically call the `initialize()` function for initialization after deployment.

### 4. Configure Contract Addresses

```solidity
// Set roles configuration contract address
epochPaymentContract.setRolesCfgAddress(rolesCfgAddress);

// Set Agent contract address
epochPaymentContract.setAgentAddress(agentAddress);
```

## Usage

### User Pay Epoch Fee

```solidity
// Pay 0.001 ETH to update Agent time period
epochPaymentContract.payEpochFee(agentSid, { value: ethers.utils.parseEther("0.001") });
```

### Admin Free Update

```solidity
// Admin can update Agent time period for free
epochPaymentContract.adminPayEpochFee(agentSid);
```

### View Contract Information

```solidity
// Get Epoch fee
uint256 fee = epochPaymentContract.getEpochPaymentAmount();

// Get Epoch duration
uint256 duration = epochPaymentContract.getEpochDuration();

// Get contract ETH balance
uint256 balance = epochPaymentContract.getContractBalance();
```

### Admin Configuration

```solidity
// Modify Epoch duration
epochPaymentContract.setEpochDuration(newDuration);
```

## Permission Management

### Owner Permissions

- Set contract addresses
- Withdraw ETH from contract
- Authorize contract upgrades

### Admin Permissions

- Update Agent time period for free
- Withdraw specified amount of ETH
- Modify Epoch duration

## Security Considerations

1. **Upgradeability**: Contract uses Initializable + OwnableUpgradeable mode, consistent with project core contracts
2. **Access Control**: Role-based access control to prevent unauthorized operations
3. **Fixed Fee**: Epoch fee is fixed at 0.001 ETH to prevent price manipulation
4. **Time Validation**: Ensures reasonableness of time periods

## Testing

Run test suite:

```bash
npx hardhat test test/HyperAGI_Agent_Epoch_Payment.ts
```

## Notes

1. Ensure all dependent contract addresses are properly configured before deployment
2. Must send exact fee amount when paying (fixed 0.001 ETH, can modify code during upgrade)
3. Agent must exist in HyperAGI_Agent contract
4. Contract uses same upgrade mode as HyperAGI_Agent.sol to ensure project consistency
5. Payment fee is fixed in method, duration can be modified through admin functions

## Dependencies

- `HyperAGI_Agent`: Main Agent management contract
- `HyperAGI_Roles_Cfg`: Role configuration contract
- OpenZeppelin upgrade contract library
