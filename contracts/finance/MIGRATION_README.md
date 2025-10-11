# HyperAGI_AgentMining 数据迁移指南

## 概述

本文档介绍如何从旧的 `HyperAGI_AgentWallet` 合约迁移到新的 `HyperAGI_AgentMining` 合约。

## 合约变更

### 旧合约：HyperAGI_AgentWallet.sol

- 用途：GPU Mining 奖励分发
- 变量前缀：`_GPUMining*`

### 新合约：HyperAGI_AgentMining.sol

- 用途：Agent Mining 奖励分发
- 变量前缀：`_AgentMining*`

## 数据迁移

### 需要迁移的存储变量

| 旧合约变量                      | 新合约变量                        | 可见性  | 迁移方式   |
| ------------------------------- | --------------------------------- | ------- | ---------- |
| `_GPUMiningTotalAward`          | `_AgentMiningTotalAward`          | public  | 直接读取   |
| `_GPUMiningCurrMiningRatio`     | `_AgentMiningCurrMiningRatio`     | private | getter函数 |
| `_GPUMiningCurrYearTotalSupply` | `_AgentMiningCurrYearTotalSupply` | private | getter函数 |
| `_epochAward`                   | `_epochAward`                     | public  | 直接读取   |
| `_GPUMiningCurrYearTotalAward`  | `_AgentMiningCurrYearTotalAward`  | private | getter函数 |
| `_GPUMiningReleaseInterval`     | `_AgentMiningReleaseInterval`     | private | getter函数 |
| `_GPUMiningRateInterval`        | `_AgentMiningRateInterval`        | private | getter函数 |
| `_GPUMiningAllowReleaseTime`    | `_AgentMiningAllowReleaseTime`    | private | getter函数 |
| `_lastGPUMiningRateTime`        | `_lastAgentMiningRateTime`        | private | getter函数 |
| `_lastGPUMiningMintTime`        | `_lastAgentMiningMintTime`        | public  | 直接读取   |
| `_GPUMiningCurrAward`           | `_AgentMiningCurrAward`           | public  | 直接读取   |
| `_TGE_timestamp`                | `_TGE_timestamp`                  | public  | 直接读取   |

## 迁移步骤

### 步骤 1：升级旧合约（添加 getter 函数）

旧合约 `HyperAGI_AgentWallet` 已经添加了以下 getter 函数来读取私有变量：

```solidity
// 批量读取所有私有变量
function getMigrationData() public view returns (uint256 GPUMiningCurrMiningRatio, uint256 GPUMiningCurrYearTotalSupply, uint256 GPUMiningCurrYearTotalAward, uint256 GPUMiningReleaseInterval, uint256 GPUMiningRateInterval, uint256 GPUMiningAllowReleaseTime, uint256 lastGPUMiningRateTime);

// 单独读取各个私有变量
function getGPUMiningCurrMiningRatio() public view returns (uint256);
function getGPUMiningCurrYearTotalSupply() public view returns (uint256);
function getGPUMiningCurrYearTotalAward() public view returns (uint256);
function getGPUMiningReleaseInterval() public view returns (uint256);
function getGPUMiningRateInterval() public view returns (uint256);
function getGPUMiningAllowReleaseTime() public view returns (uint256);
function getLastGPUMiningRateTime() public view returns (uint256);
```

**操作：** 需要先升级旧合约以添加这些 getter 函数。

### 步骤 2：部署新合约并迁移数据

有两种方式进行迁移：

#### 方式 1：初始化时自动迁移（推荐）

使用 `initializeWithMigration` 函数，在初始化时自动从旧合约读取数据：

```typescript
const HyperAGI_AgentMining = await ethers.getContractFactory('HyperAGI_AgentMining')

const agentMining = await upgrades.deployProxy(
  HyperAGI_AgentMining,
  [
    ownerAddress, // 所有者地址
    oldContractAddress, // 旧合约地址
    agentMiningReleaseInterval, // 释放间隔
  ],
  {
    initializer: 'initializeWithMigration',
    kind: 'uups',
  }
)
```

#### 方式 2：先初始化，后迁移

先使用标准的 `initialize` 函数初始化，然后手动调用 `migrateFromOldContract`：

```typescript
// 1. 标准初始化
const agentMining = await upgrades.deployProxy(HyperAGI_AgentMining, [ownerAddress, agentMiningReleaseInterval], {
  initializer: 'initialize',
  kind: 'uups',
})

// 2. 手动迁移
await agentMining.migrateFromOldContract(oldContractAddress)
```

### 步骤 3：验证迁移结果

使用以下函数验证迁移是否成功：

```typescript
// 检查迁移状态
const isMigrated = await agentMining.isMigrationCompleted()
console.log('Migration completed:', isMigrated)

// 获取迁移状态详情
const migrationState = await agentMining.getMigrationState()
console.log('Migration State:', {
  completed: migrationState.migrationCompleted,
  oldContract: migrationState.oldContractAddress,
  totalAward: migrationState.migratedTotalAward,
  currAward: migrationState.migratedCurrAward,
  tgeTimestamp: migrationState.migratedTGETimestamp,
})

// 验证具体数据
const totalAward = await agentMining._AgentMiningTotalAward()
const epochAward = await agentMining._epochAward()
const currAward = await agentMining._AgentMiningCurrAward()
```

### 步骤 4：更新系统引用

将系统中所有对 `HyperAGI_AgentWallet` 的引用更新为 `HyperAGI_AgentMining`：

1. 更新 Epoch 合约中的地址引用
2. 更新前端/后端配置中的合约地址
3. 授予 MINTER_ROLE 给需要调用 mint 的合约

```typescript
const MINTER_ROLE = await agentMining.MINTER_ROLE()
await agentMining.grantRole(MINTER_ROLE, epochContractAddress)
```

## 使用部署脚本

我们提供了完整的部署和迁移脚本：

```bash
# 设置环境变量
export OLD_AGENT_WALLET_ADDRESS=0x...  # 旧合约地址
export MINTER_ADDRESS=0x...             # 需要授予MINTER_ROLE的地址

# 运行迁移脚本
npx hardhat run scripts/HyperAGI_AgentMining_Migration.ts --network <network_name>
```

## 新合约功能

### 迁移相关函数

```solidity
// 带迁移的初始化函数
function initializeWithMigration(address onlyOwner, address oldContractAddress, uint256 AgentMiningReleaseInterval) public initializer;

// 手动迁移函数（仅owner）
function migrateFromOldContract(address oldContractAddress) public onlyOwner;

// 检查迁移状态
function isMigrationCompleted() public view returns (bool);

// 获取旧合约地址
function getOldContractAddress() public view returns (address);

// 获取迁移状态详情
function getMigrationState() public view returns (bool migrationCompleted, address oldContractAddress, uint256 migratedTotalAward, uint256 migratedCurrAward, uint256 migratedTGETimestamp);
```

### 核心业务函数

```solidity
// 铸造奖励（需要MINTER_ROLE）
function mint(address payable account, uint256 mintNum) public onlyRole(MINTER_ROLE);

// 启动TGE
function startTGE(uint256 TGE_timestamp) public onlyOwner;

// 查询当前可铸造数量
function getAgentMiningCurrAllowMintTotalNum() public view returns (uint256 allowMintNum, uint256 currYearTotalSupply, uint256 epochAward);

// 重新计算总奖励
function recalculateAgentMiningTotalAward() public onlyOwner;
```

## 安全注意事项

1. **升级顺序**：必须先升级旧合约添加 getter 函数，再部署新合约
2. **权限管理**：确保只有授权地址才能调用 `mint` 函数
3. **迁移验证**：迁移后务必验证所有数据是否正确
4. **一次性迁移**：每个合约只能执行一次迁移（通过 `_migrationCompleted` 标志控制）
5. **测试环境**：建议先在测试网络上完整测试迁移流程
6. **余额转移**：不要忘记将旧合约的 ETH 余额转移到新合约

## 迁移检查清单

- [ ] 升级旧合约 HyperAGI_AgentWallet 添加 getter 函数
- [ ] 验证旧合约的 getter 函数工作正常
- [ ] 部署新合约 HyperAGI_AgentMining（带迁移）
- [ ] 验证迁移数据的正确性
- [ ] 将旧合约余额转移到新合约
- [ ] 授予新合约 MINTER_ROLE
- [ ] 更新系统中所有合约地址引用
- [ ] 暂停旧合约的使用（如需要）
- [ ] 监控新合约运行状态
- [ ] 更新文档和配置

## 故障排查

### 问题 1：迁移失败 - "Invalid old contract address"

**原因**：提供的旧合约地址无效或为零地址  
**解决**：检查并提供正确的旧合约地址

### 问题 2：迁移失败 - "Migration already completed"

**原因**：尝试重复执行迁移  
**解决**：使用 `isMigrationCompleted()` 检查状态，如需重新迁移则需要部署新合约实例

### 问题 3：数据不匹配

**原因**：旧合约未升级或 getter 函数未正确实现  
**解决**：先升级旧合约，确保 getter 函数可用

### 问题 4：mint 调用失败 - "AccessControl: account ... is missing role"

**原因**：调用者没有 MINTER_ROLE  
**解决**：使用 owner 账户授予 MINTER_ROLE：

```typescript
await agentMining.grantRole(MINTER_ROLE, callerAddress)
```

## 联系与支持

如有问题，请联系开发团队或在项目仓库提交 issue。
