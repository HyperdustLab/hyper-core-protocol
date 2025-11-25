# 任务奖励接口使用文档

## createTaskReward - 创建任务奖励

创建新的任务奖励记录并立即将奖励转账到代理钱包。

```json
[
  {
    "contractAddress": "合约地址",
    "methodName": "createTaskReward",
    "blockchainId": "区块链ID",
    "inputs": [
      {
        "type": "uint256",
        "value": "1",
        "description": "办公室ID"
      },
      {
        "type": "bytes32",
        "value": "0x...",
        "description": "员工标识符(代理SID)"
      },
      {
        "type": "uint256",
        "value": "1",
        "description": "员工合同ID"
      },
      {
        "type": "string",
        "value": "TASK-2025-001",
        "description": "任务唯一标识符"
      },
      {
        "type": "string",
        "value": "TASK-001",
        "description": "任务ID"
      },
      {
        "type": "string",
        "value": "开发智能合约",
        "description": "任务名称"
      },
      {
        "type": "string",
        "value": "完成ERC20代币合约开发",
        "description": "任务摘要"
      },
      {
        "type": "string",
        "value": "2025-02-01",
        "description": "截止日期"
      },
      {
        "type": "string",
        "value": "已完成",
        "description": "任务状态"
      },
      {
        "type": "string",
        "value": "合约已部署到测试网",
        "description": "任务输出"
      },
      {
        "type": "string",
        "value": "任务完成质量优秀",
        "description": "经验/备注"
      }
    ],
    "value": "1000000000000000000"
  }
]
```

**说明：**

- contractAddress：任务奖励合约地址
- 参数1：办公室ID (uint256)
- 参数2：员工标识符(代理SID)，bytes32格式
- 参数3：员工合同ID (uint256)
- 参数4：任务唯一标识符 (string)，必须唯一，不能重复
- 参数5：任务ID (string)
- 参数6：任务名称 (string)
- 参数7：任务摘要 (string)
- 参数8：截止日期 (string)
- 参数9：任务状态 (string)
- 参数10：任务输出 (string)
- 参数11：经验/备注 (string)
- value: 奖励金额(wei单位，必须等于员工合同中的薪资金额，1 ETH = 10^18 wei)
- 权限：只有办公室所有者可以创建任务奖励
- 功能：创建任务奖励记录后，奖励金额会自动转账到对应的代理钱包地址

**注意事项：**

1. 任务唯一标识符(taskUniqueId)不能重复，如果已存在会报错
2. 支付的金额必须等于员工合同中定义的薪资金额
3. 员工合同必须处于激活状态(contractStatus = 0)
4. 员工合同中的办公室ID和员工标识符必须与传入参数匹配
5. 代理钱包地址必须存在且有效
6. 只有办公室所有者可以调用此函数
