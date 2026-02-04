/** @format */

import { expect } from 'chai'
import { ethers, upgrades } from 'hardhat'
import { Contract } from 'ethers'

describe('HyperAGI_Office_TaskReward CreateTaskReward Test', () => {
  let storage: Contract
  let storageHelper: Contract
  let rolesCfg: Contract
  let officeInfo: Contract
  let agent: Contract
  let employeeContract: Contract
  let taskReward: Contract

  let owner: any
  let officeOwner: any
  let otherUser: any
  let agentWallet: any

  beforeEach(async () => {
    const accounts = await ethers.getSigners()
    owner = accounts[0]
    officeOwner = accounts[1]
    otherUser = accounts[2]
    agentWallet = accounts[3]

    // 部署 HyperAGI_Storage
    const StorageFactory = await ethers.getContractFactory('HyperAGI_Storage')
    storage = await upgrades.deployProxy(StorageFactory, [owner.address], {
      initializer: 'initialize',
    })
    await storage.waitForDeployment()

    // 部署 StorageHelper 作为 serviceAddress
    const StorageHelperFactory = await ethers.getContractFactory('StorageHelper')
    storageHelper = await StorageHelperFactory.deploy(storage.target)
    await storageHelper.waitForDeployment()
    await storage.setServiceAddress(storageHelper.target)

    // 部署 HyperAGI_Roles_Cfg
    const RolesCfgFactory = await ethers.getContractFactory('HyperAGI_Roles_Cfg')
    rolesCfg = await upgrades.deployProxy(RolesCfgFactory, [owner.address], {
      initializer: 'initialize',
    })
    await rolesCfg.waitForDeployment()

    // 部署 HyperAGI_Office_Info
    const OfficeInfoFactory = await ethers.getContractFactory('HyperAGI_Office_Info')
    officeInfo = await upgrades.deployProxy(OfficeInfoFactory, [owner.address], {
      initializer: 'initialize',
    })
    await officeInfo.waitForDeployment()
    await officeInfo.setStorageAddress(storage.target)
    await officeInfo.setRolesCfgAddress(rolesCfg.target)

    // 部署 HyperAGI_Agent
    const AgentFactory = await ethers.getContractFactory('HyperAGI_Agent')
    agent = await upgrades.deployProxy(AgentFactory, [owner.address], {
      initializer: 'initialize',
    })
    await agent.waitForDeployment()
    await agent.setStorageAddress(storage.target)
    await agent.setRolesCfgAddress(rolesCfg.target)

    // 部署 HyperAGI_Employee_Contract
    const EmployeeContractFactory = await ethers.getContractFactory('HyperAGI_Employee_Contract')
    employeeContract = await upgrades.deployProxy(EmployeeContractFactory, [owner.address], {
      initializer: 'initialize',
    })
    await employeeContract.waitForDeployment()
    await employeeContract.setStorageAddress(storage.target)
    await employeeContract.setRolesCfgAddress(rolesCfg.target)
    await employeeContract.setOfficeInfoAddress(officeInfo.target)
    await employeeContract.setAgentAddress(agent.target)

    // 部署 HyperAGI_Office_TaskReward
    const TaskRewardFactory = await ethers.getContractFactory('HyperAGI_Office_TaskReward')
    taskReward = await upgrades.deployProxy(TaskRewardFactory, [owner.address], {
      initializer: 'initialize',
    })
    await taskReward.waitForDeployment()
    await taskReward.setStorageAddress(storage.target)
    await taskReward.setOfficeInfoAddress(officeInfo.target)
    await taskReward.setEmployeeContractAddress(employeeContract.target)
    await taskReward.setAgentContractAddress(agent.target)
  })

  describe('createTaskReward', () => {
    let officeId: bigint
    let contractId: bigint
    const employeeSid = ethers.id('test-employee-001')
    const spaceSid = ethers.id('test-space-001')
    const rewardAmount = ethers.parseEther('1.0') // 1 ETH

    beforeEach(async () => {
      // 设置 Storage 的 serviceAddress 为 officeInfo，以便 officeInfo 可以调用 Storage
      await storage.setServiceAddress(officeInfo.target)

      // 创建 Office
      const currentId = BigInt(await storage._id())
      await (await officeInfo.connect(officeOwner).add('Test Office', spaceSid)).wait()
      const newId = BigInt(await storage._id())
      officeId = newId - currentId

      // 设置 Storage 的 serviceAddress 为 storageHelper，以便创建 Agent 数据
      await storage.setServiceAddress(storageHelper.target)

      // 创建 Agent 数据（通过 storageHelper）
      const getNextIdTx = await storageHelper.getNextId()
      await getNextIdTx.wait()
      const agentId = BigInt(await storage._id())

      // 首先设置 sid 到 id 的映射，这样 getAgentWallet 才能找到 agent
      await storageHelper.setBytes32Uint(employeeSid, agentId)

      // 设置 agent 的其他数据
      await storageHelper.setUint(storageHelper.genKey('tokenId', agentId), 1)
      await storageHelper.setString(storageHelper.genKey('avatar', agentId), 'avatar-url')
      await storageHelper.setString(storageHelper.genKey('nickName', agentId), 'Test Agent')
      await storageHelper.setString(storageHelper.genKey('personalization', agentId), 'personalization')
      await storageHelper.setString(storageHelper.genKey('welcomeMessage', agentId), 'welcome')
      await storageHelper.setUint(storageHelper.genKey('groundRodLevel', agentId), 1)
      await storageHelper.setAddress(storageHelper.genKey('walletAddress', agentId), agentWallet.address)
      await storageHelper.setUint(storageHelper.genKey('timePeriodStart', agentId), 0)
      await storageHelper.setUint(storageHelper.genKey('timePeriodEnd', agentId), 0)
      await storageHelper.setUint(storageHelper.genKey('salary', agentId), rewardAmount) // 设置 reward 金额
      await storageHelper.setString(storageHelper.genKey('position', agentId), 'Developer')

      // 设置 Storage 的 serviceAddress 为 employeeContract，以便 employeeContract 可以调用 Storage
      await storage.setServiceAddress(employeeContract.target)

      // 创建 Employee Contract
      const currentContractId = BigInt(await storage._id())
      await (await employeeContract.connect(officeOwner).add(officeId, employeeSid, 'Senior Developer', 'Solidity, TypeScript', rewardAmount, 'Weekly', 'ETH', 'Test contract')).wait()
      const newContractId = BigInt(await storage._id())
      contractId = newContractId
    })

    it('应该成功创建任务奖励', async () => {
      // 设置 Storage 的 serviceAddress 为 taskReward，以便 taskReward 可以调用 Storage
      await storage.setServiceAddress(taskReward.target)

      const taskUniqueId = 'task-unique-001'
      const taskId = 'task-001'
      const taskName = '完成智能合约开发'
      const summary = '开发并测试智能合约功能'
      const deadline = '2025-12-31'
      const status = 'completed'
      const taskOutput = '合约已部署并测试通过'
      const exp = '100'

      // 获取 agent wallet 地址以验证余额变化
      const agentWalletAddress = await agent.getAgentWallet(employeeSid)
      expect(agentWalletAddress).to.equal(agentWallet.address)
      const balanceBefore = await ethers.provider.getBalance(agentWalletAddress)

      // 创建任务奖励，发送正确的 ETH 金额
      const tx = await taskReward.connect(officeOwner).createTaskReward(officeId, employeeSid, contractId, taskUniqueId, taskId, taskName, summary, deadline, status, taskOutput, exp, { value: rewardAmount })
      const receipt = await tx.wait()

      // 验证事件
      const event = receipt?.logs.find((log: any) => {
        try {
          const parsed = taskReward.interface.parseLog(log)
          return parsed?.name === 'eveSaveTaskReward'
        } catch {
          return false
        }
      })
      expect(event).to.not.be.undefined

      // 验证 agent wallet 余额增加
      const balanceAfter = await ethers.provider.getBalance(agentWalletAddress)
      expect(balanceAfter - balanceBefore).to.equal(rewardAmount)

      // 验证任务奖励数据
      const taskRewardId = event?.args[0] || (await storage._id())
      const taskRewardData = await taskReward.getTaskReward(taskRewardId)
      expect(taskRewardData[0]).to.equal(employeeSid) // sid
      expect(taskRewardData[1][0]).to.equal(officeId) // officeId
      expect(taskRewardData[1][1]).to.equal(contractId) // contractId
      expect(taskRewardData[1][4]).to.equal(rewardAmount) // rewardAmount
      expect(taskRewardData[2][0]).to.equal(taskUniqueId) // taskUniqueId
      expect(taskRewardData[2][1]).to.equal(taskId) // taskId
      expect(taskRewardData[2][2]).to.equal(taskName) // taskName
      expect(taskRewardData[3]).to.equal(agentWalletAddress) // recipient
    })

    it('应该拒绝空的 taskUniqueId', async () => {
      await storage.setServiceAddress(taskReward.target)

      await expect(
        taskReward.connect(officeOwner).createTaskReward(
          officeId,
          employeeSid,
          contractId,
          '', // 空的 taskUniqueId
          'task-001',
          'task name',
          'summary',
          'deadline',
          'status',
          'output',
          'exp',
          { value: rewardAmount }
        )
      ).to.be.revertedWith('task unique id required')
    })

    it('应该拒绝支付金额不匹配', async () => {
      await storage.setServiceAddress(taskReward.target)

      const wrongAmount = ethers.parseEther('0.5') // 错误的金额

      await expect(taskReward.connect(officeOwner).createTaskReward(officeId, employeeSid, contractId, 'task-unique-002', 'task-002', 'task name', 'summary', 'deadline', 'status', 'output', 'exp', { value: wrongAmount })).to.be.revertedWith('invalid payment amount')
    })

    it('应该拒绝非办公室所有者创建奖励', async () => {
      await storage.setServiceAddress(taskReward.target)

      await expect(taskReward.connect(otherUser).createTaskReward(officeId, employeeSid, contractId, 'task-unique-003', 'task-003', 'task name', 'summary', 'deadline', 'status', 'output', 'exp', { value: rewardAmount })).to.be.revertedWith('only office owner can create reward')
    })

    it('应该拒绝重复的 taskUniqueId', async () => {
      await storage.setServiceAddress(taskReward.target)

      const taskUniqueId = 'task-unique-004'

      // 第一次创建
      await (await taskReward.connect(officeOwner).createTaskReward(officeId, employeeSid, contractId, taskUniqueId, 'task-004', 'task name', 'summary', 'deadline', 'status', 'output', 'exp', { value: rewardAmount })).wait()

      // 尝试使用相同的 taskUniqueId 再次创建
      await expect(
        taskReward.connect(officeOwner).createTaskReward(
          officeId,
          employeeSid,
          contractId,
          taskUniqueId, // 重复的 taskUniqueId
          'task-004-2',
          'task name 2',
          'summary 2',
          'deadline 2',
          'status 2',
          'output 2',
          'exp 2',
          { value: rewardAmount }
        )
      ).to.be.revertedWith('task unique id exists')
    })

    it('应该拒绝不匹配的 officeId', async () => {
      // 先验证合同的 officeId
      await storage.setServiceAddress(employeeContract.target)
      const contractData = await employeeContract.getById(contractId)
      const contractOfficeId = contractData[0]
      expect(contractOfficeId).to.equal(officeId) // 确认合同属于原来的 officeId

      // 创建一个新的 office，使用不同的 spaceSid 确保是不同的 office
      await storage.setServiceAddress(officeInfo.target)
      const anotherSpaceSid = ethers.id('another-space-001')
      // 获取调用 add 之前的 _id
      const idBeforeAdd = BigInt(await storage._id())
      // 调用 add，它会调用 getNextId() 增加 _id 并返回新的 id
      await (await officeInfo.connect(officeOwner).add('Another Office', anotherSpaceSid)).wait()
      // add 方法返回的 id 就是调用 getNextId() 后的 _id，也就是 idBeforeAdd + 1
      const anotherOfficeId = idBeforeAdd + 1n

      // 确保新的 officeId 与合同的 officeId 不同
      expect(Number(anotherOfficeId)).to.not.equal(Number(contractOfficeId))

      // 验证新 office 确实存在且 officeOwner 是其 owner
      const anotherOfficeData = await officeInfo.getById(anotherOfficeId)
      expect(anotherOfficeData[1]).to.equal(officeOwner.address) // officeOwner

      await storage.setServiceAddress(taskReward.target)

      // 使用另一个 officeId，但合同属于原来的 officeId
      // _validateOfficeOwner 会通过（因为 officeOwner 是新 office 的 owner）
      // 但 _validateContract 应该检查并拒绝（因为合同属于不同的 officeId）
      await expect(
        taskReward.connect(officeOwner).createTaskReward(
          anotherOfficeId, // 错误的 officeId（与合同中的 officeId 不匹配）
          employeeSid,
          contractId,
          'task-unique-005',
          'task-005',
          'task name',
          'summary',
          'deadline',
          'status',
          'output',
          'exp',
          { value: rewardAmount }
        )
      ).to.be.revertedWith('office mismatch')
    })

    it('应该拒绝不匹配的 sid', async () => {
      await storage.setServiceAddress(taskReward.target)

      const wrongSid = ethers.id('wrong-employee')

      await expect(
        taskReward.connect(officeOwner).createTaskReward(
          officeId,
          wrongSid, // 错误的 sid
          contractId,
          'task-unique-006',
          'task-006',
          'task name',
          'summary',
          'deadline',
          'status',
          'output',
          'exp',
          { value: rewardAmount }
        )
      ).to.be.revertedWith('sid mismatch')
    })

    it('应该拒绝不存在的合同', async () => {
      await storage.setServiceAddress(taskReward.target)

      const nonExistentContractId = 999n

      await expect(
        taskReward.connect(officeOwner).createTaskReward(
          officeId,
          employeeSid,
          nonExistentContractId, // 不存在的合同 ID
          'task-unique-007',
          'task-007',
          'task name',
          'summary',
          'deadline',
          'status',
          'output',
          'exp',
          { value: rewardAmount }
        )
      ).to.be.reverted
    })

    it('应该拒绝未找到 agent wallet', async () => {
      // 设置 Storage 的 serviceAddress 为 storageHelper，以便创建 Agent 数据
      await storage.setServiceAddress(storageHelper.target)

      // 创建一个没有 walletAddress 的 agent
      const newEmployeeSid = ethers.id('employee-no-wallet')
      const getNextIdTx = await storageHelper.getNextId()
      await getNextIdTx.wait()
      const newAgentId = BigInt(await storage._id())
      await storageHelper.setBytes32Uint(newEmployeeSid, newAgentId)

      // 设置 agent 的其他数据，但不设置 walletAddress
      await storageHelper.setUint(storageHelper.genKey('tokenId', newAgentId), 1)
      await storageHelper.setString(storageHelper.genKey('avatar', newAgentId), 'avatar-url')
      await storageHelper.setString(storageHelper.genKey('nickName', newAgentId), 'Test Agent No Wallet')
      await storageHelper.setString(storageHelper.genKey('personalization', newAgentId), 'personalization')
      await storageHelper.setString(storageHelper.genKey('welcomeMessage', newAgentId), 'welcome')
      await storageHelper.setUint(storageHelper.genKey('groundRodLevel', newAgentId), 1)
      // 不设置 walletAddress，让它保持为 address(0)
      await storageHelper.setUint(storageHelper.genKey('timePeriodStart', newAgentId), 0)
      await storageHelper.setUint(storageHelper.genKey('timePeriodEnd', newAgentId), 0)
      await storageHelper.setUint(storageHelper.genKey('salary', newAgentId), rewardAmount)
      await storageHelper.setString(storageHelper.genKey('position', newAgentId), 'Developer')

      // 创建新的合同
      await storage.setServiceAddress(employeeContract.target)
      const currentContractId = BigInt(await storage._id())
      await (await employeeContract.connect(officeOwner).add(officeId, newEmployeeSid, 'Developer', 'Skills', rewardAmount, 'Weekly', 'ETH', 'Test')).wait()
      const newContractId = BigInt(await storage._id())

      await storage.setServiceAddress(taskReward.target)

      await expect(taskReward.connect(officeOwner).createTaskReward(officeId, newEmployeeSid, newContractId, 'task-unique-008', 'task-008', 'task name', 'summary', 'deadline', 'status', 'output', 'exp', { value: rewardAmount })).to.be.revertedWith('agent wallet not found')
    })

    it('应该正确处理空的字符串参数', async () => {
      await storage.setServiceAddress(taskReward.target)

      const taskUniqueId = 'task-unique-009'

      // 创建任务奖励，某些字符串参数为空
      const tx = await taskReward.connect(officeOwner).createTaskReward(
        officeId,
        employeeSid,
        contractId,
        taskUniqueId,
        'task-009',
        'task name',
        '', // 空的 summary
        '', // 空的 deadline
        '', // 空的 status
        '', // 空的 taskOutput
        '', // 空的 exp
        { value: rewardAmount }
      )
      const receipt = await tx.wait()

      // 验证事件
      const event = receipt?.logs.find((log: any) => {
        try {
          const parsed = taskReward.interface.parseLog(log)
          return parsed?.name === 'eveSaveTaskReward'
        } catch {
          return false
        }
      })
      expect(event).to.not.be.undefined

      // 验证数据已保存（即使字符串为空）
      const taskRewardId = event?.args[0] || (await storage._id())
      const taskRewardData = await taskReward.getTaskReward(taskRewardId)
      expect(taskRewardData[2][0]).to.equal(taskUniqueId) // taskUniqueId 不为空
      expect(taskRewardData[2][3]).to.equal('') // summary 为空
    })

    it('使用截图中的参数测试合约执行', async () => {
      // 使用 beforeEach 中创建的 officeId 和 contractId（正常的 ID）
      // 但使用截图中的其他参数（字符串参数）
      const screenshotSid = '0x4f61db87f7a7bd15586f9afc64d9b13a85c11af332786f3580ac77083a515054'
      const screenshotTaskUniqueId = '1765483586108'
      const screenshotTaskId = '1765483586108'
      const screenshotTaskName = '1'
      const screenshotSummary = ''
      const screenshotDeadline = ''
      const screenshotStatus = ''
      const screenshotTaskOutput = ''
      const screenshotExp = ''

      // 使用截图中的 sid 创建新的 agent 数据（如果与现有的不同）
      await storage.setServiceAddress(storageHelper.target)
      const agentSid = screenshotSid as `0x${string}`

      // 检查这个 sid 是否已经存在
      const existingAgentId = await storage.getBytes32Uint(agentSid)
      let agentId: bigint

      if (existingAgentId === 0n) {
        // 如果不存在，创建新的 agent 数据
        const getNextIdTx = await storageHelper.getNextId()
        await getNextIdTx.wait()
        agentId = BigInt(await storage._id())

        await storageHelper.setBytes32Uint(agentSid, agentId)
        await storageHelper.setUint(storageHelper.genKey('tokenId', agentId), 1)
        await storageHelper.setString(storageHelper.genKey('avatar', agentId), 'avatar-url')
        await storageHelper.setString(storageHelper.genKey('nickName', agentId), 'Test Agent')
        await storageHelper.setString(storageHelper.genKey('personalization', agentId), 'personalization')
        await storageHelper.setString(storageHelper.genKey('welcomeMessage', agentId), 'welcome')
        await storageHelper.setUint(storageHelper.genKey('groundRodLevel', agentId), 1)
        await storageHelper.setAddress(storageHelper.genKey('walletAddress', agentId), agentWallet.address)
        await storageHelper.setUint(storageHelper.genKey('timePeriodStart', agentId), 0)
        await storageHelper.setUint(storageHelper.genKey('timePeriodEnd', agentId), 0)
        await storageHelper.setUint(storageHelper.genKey('salary', agentId), rewardAmount)
        await storageHelper.setString(storageHelper.genKey('position', agentId), 'Developer')
      } else {
        // 如果已存在，使用现有的 agentId
        agentId = existingAgentId
        // 确保 walletAddress 已设置
        const existingWallet = await storage.getAddress(storage.genKey('walletAddress', agentId))
        if (existingWallet === ethers.ZeroAddress) {
          await storageHelper.setAddress(storageHelper.genKey('walletAddress', agentId), agentWallet.address)
        }
        // 确保 salary 已设置
        const existingSalary = await storage.getUint(storage.genKey('salary', agentId))
        if (existingSalary === 0n) {
          await storageHelper.setUint(storageHelper.genKey('salary', agentId), rewardAmount)
        }
      }

      // 如果 sid 与现有的不同，需要创建新的 contract
      let testContractId = contractId
      if (agentSid !== employeeSid) {
        // 创建新的 contract 使用截图中的 sid
        await storage.setServiceAddress(employeeContract.target)
        const currentContractId = BigInt(await storage._id())
        await (await employeeContract.connect(officeOwner).add(officeId, agentSid, 'Developer', 'Skills', rewardAmount, 'Weekly', 'ETH', 'Test')).wait()
        const newContractId = BigInt(await storage._id())
        testContractId = newContractId
      }

      await storage.setServiceAddress(taskReward.target)

      // 使用截图中的参数调用 createTaskReward（使用正常的 officeId 和 contractId）
      console.log('使用截图参数调用 createTaskReward:')
      console.log('  officeId:', officeId.toString(), '(使用 beforeEach 中创建的)')
      console.log('  sid:', screenshotSid)
      console.log('  contractId:', testContractId.toString(), '(使用 beforeEach 中创建的或新创建的)')
      console.log('  taskUniqueId:', screenshotTaskUniqueId)
      console.log('  taskId:', screenshotTaskId)
      console.log('  taskName:', screenshotTaskName)
      console.log('  summary:', screenshotSummary || '(空)')
      console.log('  deadline:', screenshotDeadline || '(空)')
      console.log('  status:', screenshotStatus || '(空)')
      console.log('  taskOutput:', screenshotTaskOutput || '(空)')
      console.log('  exp:', screenshotExp || '(空)')

      try {
        const tx = await taskReward.connect(officeOwner).createTaskReward(
          officeId, // 使用正常的 officeId
          agentSid, // 使用截图中的 sid
          testContractId, // 使用正常的 contractId
          screenshotTaskUniqueId,
          screenshotTaskId,
          screenshotTaskName,
          screenshotSummary,
          screenshotDeadline,
          screenshotStatus,
          screenshotTaskOutput,
          screenshotExp,
          { value: rewardAmount }
        )
        const receipt = await tx.wait()

        console.log('✓ 交易成功')
        console.log('  交易哈希:', receipt?.hash)

        // 查找事件
        const event = receipt?.logs.find((log: any) => {
          try {
            const parsed = taskReward.interface.parseLog(log)
            return parsed?.name === 'eveSaveTaskReward'
          } catch {
            return false
          }
        })

        if (event) {
          const taskRewardId = event.args[0]
          console.log('  创建的任务奖励 ID:', taskRewardId.toString())

          // 读取创建的数据
          const taskRewardData = await taskReward.getTaskReward(taskRewardId)
          console.log('  任务奖励数据:')
          console.log('    sid:', taskRewardData[0])
          console.log('    officeId:', taskRewardData[1][0].toString())
          console.log('    contractId:', taskRewardData[1][1].toString())
          console.log('    rewardAmount:', taskRewardData[1][4].toString())
          console.log('    taskUniqueId:', taskRewardData[2][0])
          console.log('    taskId:', taskRewardData[2][1])
          console.log('    taskName:', taskRewardData[2][2])
          console.log('    summary:', taskRewardData[2][3] || '(空)')
          console.log('    deadline:', taskRewardData[2][4] || '(空)')
          console.log('    status:', taskRewardData[2][5] || '(空)')
          console.log('    taskOutput:', taskRewardData[2][6] || '(空)')
          console.log('    exp:', taskRewardData[2][7] || '(空)')
          console.log('    recipient:', taskRewardData[3])
        }
      } catch (error: any) {
        console.log('✗ 交易失败')
        console.log('  错误信息:', error.message)
        if (error.reason) {
          console.log('  失败原因:', error.reason)
        }
        // 重新抛出错误以便测试框架捕获
        throw error
      }
    })
  })
})
