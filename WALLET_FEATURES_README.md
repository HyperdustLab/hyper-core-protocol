# HyperAGI_Agent 钱包地址库功能说明

## 功能概述

HyperAGI_Agent合约已新增钱包地址库功能，支持为每个Agent自动分配唯一的钱包地址，并在分配时进行ETH转账。

## 新增功能

### 1. 钱包地址库管理

#### 添加钱包地址到地址库
```solidity
function addWalletToPool(address[] memory walletAddresses) public onlyAdmin
```
- **功能**: 向钱包地址库中添加新的钱包地址
- **权限**: 仅管理员角色可调用
- **参数**: `walletAddresses` - 要添加的钱包地址数组
- **事件**: `eveWalletAdded(address walletAddress)`

#### 查看钱包地址库状态
```solidity
function getWalletPoolInfo() public view returns (uint256 totalWallets, uint256 allocatedWallets, uint256 availableWallets)
```
- **返回值**: 
  - `totalWallets`: 地址库中的总钱包数量
  - `allocatedWallets`: 已分配的钱包数量
  - `availableWallets`: 可用的钱包数量

#### 获取钱包地址库
```solidity
function getWalletPool() public view returns (address[] memory)
```
- **返回值**: 地址库中的所有钱包地址

#### 检查钱包是否已分配
```solidity
function isWalletAllocated(address wallet) public view returns (bool)
```
- **功能**: 检查指定钱包地址是否已被分配

### 2. 转账金额设置

#### 设置默认转账金额
```solidity
function setDefaultTransferAmount(uint256 amount) public onlyAdmin
```
- **功能**: 设置mintV3时向分配钱包转账的默认金额
- **权限**: 仅管理员角色可调用
- **默认值**: 1 ETH
- **事件**: `eveTransferAmountUpdated(uint256 newAmount)`

### 3. 增强的mintV3功能

#### 自动钱包分配和转账
```solidity
function mintV3(uint256 tokenId, string[] memory strParams) public payable
```
- **新增功能**:
  - 自动从钱包地址库中分配一个未使用的钱包地址
  - 将分配的钱包地址与Agent关联存储
  - 向分配的钱包地址转账指定金额的ETH
- **事件**: `eveWalletAllocated(bytes32 sid, address walletAddress, uint256 transferAmount)`

### 4. Agent钱包地址查询

#### 获取Agent的钱包地址
```solidity
function getAgentWallet(bytes32 sid) public view returns (address)
```
- **功能**: 根据Agent的SID获取其关联的钱包地址

#### 获取Agent完整信息（包含钱包地址）
```solidity
function getAgentV3(bytes32 sid) public view returns (uint256, string memory, string memory, string memory, string memory, uint256, address)
```
- **返回值**: 包含钱包地址的完整Agent信息

## 使用流程

### 1. 初始化钱包地址库
```javascript
// 管理员添加钱包地址到地址库
const walletAddresses = [
    "0x1234567890123456789012345678901234567890",
    "0x2345678901234567890123456789012345678901",
    "0x3456789012345678901234567890123456789012"
];
await agent.addWalletToPool(walletAddresses);
```

### 2. 设置转账金额
```javascript
// 设置转账金额为0.5 ETH
await agent.setDefaultTransferAmount(ethers.parseEther("0.5"));
```

### 3. 向合约发送ETH
```javascript
// 向合约发送ETH用于转账
await deployer.sendTransaction({
    to: agentAddress,
    value: ethers.parseEther("10.0")
});
```

### 4. 创建Agent（自动分配钱包）
```javascript
const strParams = [
    "avatar_url",
    "Agent名称",
    "Agent描述",
    "欢迎消息"
];

// mintV3会自动分配钱包地址并转账
const tx = await agent.mintV3(1, strParams);
const receipt = await tx.wait();

// 监听钱包分配事件
const walletAllocatedEvent = receipt.logs.find(log => {
    const parsed = agent.interface.parseLog(log);
    return parsed?.name === "eveWalletAllocated";
});
```

### 5. 查询Agent钱包地址
```javascript
// 获取Agent的钱包地址
const agentWallet = await agent.getAgentWallet(agentSid);
console.log("Agent钱包地址:", agentWallet);

// 获取完整Agent信息
const agentInfo = await agent.getAgentV3(agentSid);
console.log("Agent完整信息:", agentInfo);
```

## 安全特性

1. **权限控制**: 只有管理员角色可以添加钱包地址和设置转账金额
2. **防重复分配**: 已分配的钱包地址不会再次被分配
3. **地址验证**: 添加钱包地址时会验证地址有效性
4. **转账安全**: 使用`call`方法进行安全的ETH转账

## 事件说明

- `eveWalletAllocated`: 钱包分配事件，包含SID、钱包地址和转账金额
- `eveWalletAdded`: 钱包地址添加到地址库事件
- `eveTransferAmountUpdated`: 转账金额更新事件

## 注意事项

1. 确保合约中有足够的ETH用于转账
2. 钱包地址库为空时无法创建Agent
3. 所有钱包地址分配完毕后需要添加新的钱包地址
4. 转账金额不应超过合约余额
5. 建议定期检查钱包地址库的可用数量

## 测试

运行测试脚本验证功能：
```bash
npx hardhat run scripts/HyperAGI_Agent_Wallet_Test.ts --network localhost
```
