/** @format */

import { expect } from 'chai'
import { ethers, upgrades } from 'hardhat'
import { Contract } from 'ethers'

describe('HyperAGI_Employee_Contract Terminate Test', () => {
  let storage: Contract
  let storageHelper: Contract
  let rolesCfg: Contract
  let officeInfo: Contract
  let agent: Contract
  let employeeContract: Contract

  let owner: any
  let officeOwner: any
  let otherUser: any

  beforeEach(async () => {
    const accounts = await ethers.getSigners()
    owner = accounts[0]
    officeOwner = accounts[1]
    otherUser = accounts[2]

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

    // 设置 Employee Contract 的依赖地址
    await employeeContract.setStorageAddress(storage.target)
    await employeeContract.setRolesCfgAddress(rolesCfg.target)
    await employeeContract.setOfficeInfoAddress(officeInfo.target)
    await employeeContract.setAgentAddress(agent.target)
  })

  describe('terminate', () => {
    let officeId: bigint
    let contractId: bigint
    const employeeSid = ethers.id('test-employee-001')
    const spaceSid = ethers.id('test-space-001')

    beforeEach(async () => {
      // 设置 Storage 的 serviceAddress 为 officeInfo，以便 officeInfo 可以调用 Storage
      await storage.setServiceAddress(officeInfo.target)

      // 创建 Office - 获取当前 id，然后创建，id 就是返回值
      const currentId = BigInt(await storage._id())
      await (await officeInfo.connect(officeOwner).add('Test Office', spaceSid)).wait()
      const newId = BigInt(await storage._id())
      officeId = newId - currentId

      // 设置 Storage 的 serviceAddress 为 storageHelper，以便创建 Agent 数据
      await storage.setServiceAddress(storageHelper.target)

      // 创建 Agent 数据（通过 storageHelper）
      // 调用 getNextId 获取新的 id（会自动递增 _id）
      const getNextIdTx = await storageHelper.getNextId()
      await getNextIdTx.wait()
      const agentId = BigInt(await storage._id()) // getNextId 已经自增了，所以直接使用当前 id

      // 首先设置 sid 到 id 的映射，这样 getAgentV4 才能找到 agent
      await storageHelper.setBytes32Uint(employeeSid, agentId)

      // 然后设置 agent 的其他数据
      await storageHelper.setUint(storageHelper.genKey('tokenId', agentId), 1)
      await storageHelper.setString(storageHelper.genKey('avatar', agentId), 'avatar-url')
      await storageHelper.setString(storageHelper.genKey('nickName', agentId), 'Test Agent')
      await storageHelper.setString(storageHelper.genKey('personalization', agentId), 'personalization')
      await storageHelper.setString(storageHelper.genKey('welcomeMessage', agentId), 'welcome')
      await storageHelper.setUint(storageHelper.genKey('groundRodLevel', agentId), 1)
      await storageHelper.setAddress(storageHelper.genKey('walletAddress', agentId), officeOwner.address)
      await storageHelper.setUint(storageHelper.genKey('timePeriodStart', agentId), 0)
      await storageHelper.setUint(storageHelper.genKey('timePeriodEnd', agentId), 0)
      await storageHelper.setUint(storageHelper.genKey('salary', agentId), ethers.parseEther('100'))
      await storageHelper.setString(storageHelper.genKey('position', agentId), 'Developer')

      // 设置 Storage 的 serviceAddress 为 employeeContract，以便 employeeContract 可以调用 Storage
      await storage.setServiceAddress(employeeContract.target)

      // 创建 Employee Contract - 获取当前 id，然后创建，新的 id 就是 contractId
      const currentContractId = BigInt(await storage._id())
      await (await employeeContract.connect(officeOwner).add(officeId, employeeSid, 'Senior Developer', 'Solidity, TypeScript', ethers.parseEther('100'), 'Weekly', 'ETH', 'Test contract')).wait()
      const newContractId = BigInt(await storage._id())
      contractId = newContractId // add 方法会调用 getNextId()，所以新的 id 就是 contractId
    })

    it('应该成功终止合同（office owner）', async () => {
      // 确保 Storage 的 serviceAddress 设置为 employeeContract
      await storage.setServiceAddress(employeeContract.target)

      // 验证合同状态为正常（0）- 直接从 storage 读取，避免调用 getById（因为 getById 需要 agent 数据）
      const contractStatusBefore = await storage.getUint(storage.genKey('contractStatus', contractId))
      expect(contractStatusBefore).to.equal(0)

      // 终止合同
      const terminateTx = await employeeContract.connect(officeOwner).terminate(contractId)
      await terminateTx.wait()

      // 验证合同状态已变为终止（1）- 直接从 storage 读取
      const contractStatusAfter = await storage.getUint(storage.genKey('contractStatus', contractId))
      expect(contractStatusAfter).to.equal(1)
    })

    it('应该拒绝非 office owner 终止合同', async () => {
      await storage.setServiceAddress(employeeContract.target)
      await expect(employeeContract.connect(otherUser).terminate(contractId)).to.be.revertedWith('only office owner can terminate contract')
    })

    it('应该拒绝终止已终止的合同', async () => {
      await storage.setServiceAddress(employeeContract.target)
      // 第一次终止
      await employeeContract.connect(officeOwner).terminate(contractId)

      // 尝试再次终止
      await expect(employeeContract.connect(officeOwner).terminate(contractId)).to.be.revertedWith('contract already terminated')
    })

    it('应该拒绝终止不存在的合同', async () => {
      await storage.setServiceAddress(employeeContract.target)
      const nonExistentId = 999n
      await expect(employeeContract.connect(officeOwner).terminate(nonExistentId)).to.be.revertedWith('contract not found')
    })

    it('应该拒绝终止无效的合同 ID（0）', async () => {
      await storage.setServiceAddress(employeeContract.target)
      await expect(employeeContract.connect(officeOwner).terminate(0)).to.be.revertedWith('invalid id')
    })

    it('应该发出 eveSaveContract 事件', async () => {
      await storage.setServiceAddress(employeeContract.target)
      const terminateTx = await employeeContract.connect(officeOwner).terminate(contractId)
      const receipt = await terminateTx.wait()

      const event = receipt?.logs.find((log: any) => log.fragment?.name === 'eveSaveContract')
      expect(event).to.not.be.undefined
      expect(event?.args[0]).to.equal(contractId)
    })
  })
})
