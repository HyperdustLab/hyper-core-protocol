# Agent Count Management Feature Description

## Overview

This feature adds agent total count and online count tracking and management functionality to the HyperAGI protocol.

## New Features

### HyperAGI_Agent.sol Contract New Features

#### State Variables

- `totalAgentCount`: Stores total agent count
- `onlineAgentCount`: Stores online agent count

#### New Methods

1. **setAgentCounts(uint256 \_totalCount, uint256 \_onlineCount)**
   - Set agent total count and online count
   - Only admin can call
   - Validates that online count cannot exceed total count
   - Triggers `eveAgentCountUpdated` event

2. **getAgentCounts()**
   - Returns (total count, online count) tuple
   - Public method, anyone can call

3. **getTotalAgentCount()**
   - Returns agent total count
   - Public method

4. **getOnlineAgentCount()**
   - Returns online agent count
   - Public method

#### New Events

- `eveAgentCountUpdated(uint256 totalCount, uint256 onlineCount)`: Triggered when agent count is updated

### HyperAGI_Agent_Epoch_Awards.sol Contract Modifications

#### Modifications

Added automatic agent count update functionality in the `rewards` method:

```solidity
// Update agent counts in HyperAGI_Agent contract
agentAddress.setAgentCounts(_totalNum, activeNumIndex);
```

## Usage Examples

### Set Agent Count

```solidity
// Set total count to 1000, online count to 800
await agentContract.setAgentCounts(1000, 800);
```

### Get Agent Count

```solidity
// Get total count and online count
const [totalCount, onlineCount] = await agentContract.getAgentCounts();

// Or get separately
const totalCount = await agentContract.getTotalAgentCount();
const onlineCount = await agentContract.getOnlineAgentCount();
```

### Automatic Update in Epoch Reward Distribution

When calling the `HyperAGI_Agent_Epoch_Awards.rewards()` method, the system will automatically update agent count:

- `_totalNum`: Set to total agent count
- `activeNumIndex`: Set to online agent count

## Permission Control

- Only addresses with admin role can call `setAgentCounts` method
- Get methods are open to all users

## Validation Rules

- Online count cannot exceed total count
- If this rule is violated, the transaction will be reverted with an error message

## Event Listening

You can track agent count changes by listening to the `eveAgentCountUpdated` event:

```solidity
agentContract.on("eveAgentCountUpdated", (totalCount, onlineCount) => {
    console.log(`Agent counts updated: Total=${totalCount}, Online=${onlineCount}`);
});
```
