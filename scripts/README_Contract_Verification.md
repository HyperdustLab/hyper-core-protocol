# Contract Upgrade and Verification Instructions

## Problem Description

After upgrading the contract, source code verification failed with "Contract Source Code Verified (Partial Match)" error.

## Solution

### Method 1: Use Modified Upgrade Script

```bash
npx hardhat run scripts/HyperAGI_Agent_Update.ts --network hyperAGI
```

### Method 2: Use Dedicated Verification Script

```bash
npx hardhat run scripts/Verify_Upgraded_Contract.ts --network hyperAGI
```

### Method 3: Manual Verification

If automatic verification fails, you can manually verify in browser:

1. Visit: https://explorer.hyperagi.network/address/0xBAa6ED7fA9B636a319160d68fCFb30BbB91E4319
2. Click "Contract" tab
3. Click "Verify and Publish" button
4. Select "Solidity (Single file)" or "Solidity (Standard JSON Input)"
5. Enter contract source code and constructor arguments

### Method 4: Use Command Line Force Verification

```bash
npx hardhat verify --network hyperAGI --force 0xBAa6ED7fA9B636a319160d68fCFb30BbB91E4319
```

## Important Notes

1. **Proxy Contract Address**: `0xD493BF696b0c98397a87470980f1afCc22CDb289`
2. **Implementation Contract Address**: Needs to be obtained through script, usually `0xBAa6ED7fA9B636a319160d68fCFb30BbB91E4319`
3. **Network**: hyperAGI
4. **Constructor Arguments**: Empty array `[]`

## Verification Steps

1. Run upgrade script
2. Wait for block confirmations (about 10 seconds)
3. Automatically verify implementation contract
4. If failed, manual verification

## Common Issues

### Q: Why does partial verification error occur?

A: This is because the contract has been partially verified before, need to use `--force` flag to force re-verification.

### Q: What to do if verification fails?

A: You can try multiple methods:

- Use `--force` flag
- Manual verification in browser
- Check network connection and API key

### Q: How to confirm verification success?

A: Check the contract address in browser, you should see complete source code and ABI.
