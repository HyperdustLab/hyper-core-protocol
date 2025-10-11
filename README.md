# Hyperdust Protocol Smart Contracts

The **Hyperdust Protocol** is composed of modular smart contracts, each handling a specific role in mining, governance, transactions, and token distribution within the HyperAGI ecosystem.

---

## 🪙 Core Token & Wallet Contracts
- **Hyperdust_Token.sol**  
  The main token contract of the Hyperdust Protocol, defining the native token **HYPT**.

- **Hyperdust_Wallet_Account.sol**  
  Manages wallet accounts, holding Hyper gas fees on the L2 chain and generating detailed transaction records.

- **Hyperdust_VestingWallet.sol**  
  Responsible for controlled release of tokens allocated for:
  - Airdrop
  - PublicSale
  - PrivateSale
  - Seed
  - Advisor
  - Foundation
  - CoreTeam

---

## 🎁 Airdrop & Distribution Contracts
- **Hyperdust_AirDrop.sol**  
  Bulk airdrop contract for centralized token distribution.

- **Hyperdust_Faucet.sol**  
  Faucet contract enabling users to claim small amounts of HYPT.

- **Hyperdust_BaseReward_Release.sol**  
  Handles periodic release of mined tokens to miners according to reward cycles.

---

## ⛏️ Mining & Node Management Contracts
- **Hyperdust_Epoch_Awards.sol**  
  The primary mining contract, distributing HYPT to miners for each epoch.

- **Hyperdust_GPUMining.sol**  
  Mining wallet contract for storing monthly mining token funds.

- **Hyperdust_Node_CheckIn.sol**  
  On-chain miner registration verification.

- **Hyperdust_Node_Mgr.sol**  
  Manages miner node information: status, online numbers, rendering workloads, etc.

- **Hyperdust_Node_Type.sol**  
  Maintains miner type classifications and categories.

- **Hyperdust_Security_Deposit.sol**  
  Requires miners to deposit 10% of mined HYPT as a quality guarantee.

---

## ⚙️ Transaction & Economic Configuration Contracts
- **Hyperdust_Transaction_Cfg.sol**  
  Stores gas cost configurations for different protocol modules and minimum gas authorization.

- **Hyperdust_Epoch_Transaction.sol**  
  Executes epoch-based transactions, leveraging Hyperdust computing resources.

---

## 🏛️ Governance & Role Management Contracts
- **Hyperdust_Roles_Cfg.sol**  
  Defines and maintains global administrator roles.

- **Hyperdust_GYM_Space.sol**  
  Manages Hyperspaces and generates unique **SID (Space Identifier)** for each.

---
