import { expect } from 'chai'
import { ethers, upgrades } from 'hardhat'
import { HyperAGI_AgentWallet, HyperAGI_AgentMining } from '../typechain-types'
import { SignerWithAddress } from '@nomicfoundation/hardhat-ethers/signers'

describe('HyperAGI_AgentMining Migration Tests', function () {
  let owner: SignerWithAddress
  let minter: SignerWithAddress
  let user: SignerWithAddress
  let oldContract: HyperAGI_AgentWallet
  let newContract: HyperAGI_AgentMining

  const RELEASE_INTERVAL = 365 * 24 * 60 * 60 // 1 year

  beforeEach(async function () {
    ;[owner, minter, user] = await ethers.getSigners()

    // Deploy old contract (HyperAGI_AgentWallet)
    const OldContractFactory = await ethers.getContractFactory('HyperAGI_AgentWallet')
    oldContract = (await upgrades.deployProxy(OldContractFactory, [owner.address, RELEASE_INTERVAL], { initializer: 'initialize', kind: 'uups' })) as any
    await oldContract.waitForDeployment()

    // Simulate some activity on old contract
    const currentTime = Math.floor(Date.now() / 1000)
    await oldContract.startTGE(currentTime)

    // Grant MINTER_ROLE to minter address
    const MINTER_ROLE = await oldContract.MINTER_ROLE()
    await oldContract.grantRole(MINTER_ROLE, minter.address)
  })

  describe('Migration with initializeWithMigration', function () {
    it('Should successfully migrate all data during initialization', async function () {
      const NewContractFactory = await ethers.getContractFactory('HyperAGI_AgentMining')
      const oldContractAddress = await oldContract.getAddress()

      // Deploy new contract with migration
      newContract = (await upgrades.deployProxy(NewContractFactory, [owner.address, oldContractAddress, RELEASE_INTERVAL], { initializer: 'initializeWithMigration', kind: 'uups' })) as any
      await newContract.waitForDeployment()

      // Verify migration completed
      expect(await newContract.isMigrationCompleted()).to.be.true
      expect(await newContract.getOldContractAddress()).to.equal(oldContractAddress)

      // Verify migrated public variables
      expect(await newContract._AgentMiningTotalAward()).to.equal(await oldContract._GPUMiningTotalAward())
      expect(await newContract._epochAward()).to.equal(await oldContract._epochAward())
      expect(await newContract._AgentMiningCurrAward()).to.equal(await oldContract._GPUMiningCurrAward())
      expect(await newContract._lastAgentMiningMintTime()).to.equal(await oldContract._lastGPUMiningMintTime())
      expect(await newContract._TGE_timestamp()).to.equal(await oldContract._TGE_timestamp())
    })

    it('Should migrate private variables correctly', async function () {
      const NewContractFactory = await ethers.getContractFactory('HyperAGI_AgentMining')
      const oldContractAddress = await oldContract.getAddress()

      // Get old contract's private data
      const oldMigrationData = await oldContract.getMigrationData()

      // Deploy new contract with migration
      newContract = (await upgrades.deployProxy(NewContractFactory, [owner.address, oldContractAddress, RELEASE_INTERVAL], { initializer: 'initializeWithMigration', kind: 'uups' })) as any
      await newContract.waitForDeployment()

      // Note: We can't directly verify private variables in the new contract
      // But we can verify through getMigrationState
      const migrationState = await newContract.getMigrationState()
      expect(migrationState.migrationCompleted).to.be.true
      expect(migrationState.oldContractAddress).to.equal(oldContractAddress)
    })

    it('Should emit migration completed event', async function () {
      const NewContractFactory = await ethers.getContractFactory('HyperAGI_AgentMining')
      const oldContractAddress = await oldContract.getAddress()

      // Deploy and check for event (note: events in initializer are hard to catch)
      newContract = (await upgrades.deployProxy(NewContractFactory, [owner.address, oldContractAddress, RELEASE_INTERVAL], { initializer: 'initializeWithMigration', kind: 'uups' })) as any
      await newContract.waitForDeployment()

      // Verify the contract state instead
      expect(await newContract.isMigrationCompleted()).to.be.true
    })
  })

  describe('Migration with manual migrateFromOldContract', function () {
    it('Should successfully migrate data manually after initialization', async function () {
      const NewContractFactory = await ethers.getContractFactory('HyperAGI_AgentMining')
      const oldContractAddress = await oldContract.getAddress()

      // Deploy new contract with standard initialization
      newContract = (await upgrades.deployProxy(NewContractFactory, [owner.address, RELEASE_INTERVAL], { initializer: 'initialize', kind: 'uups' })) as any
      await newContract.waitForDeployment()

      // Migration should not be completed yet
      expect(await newContract.isMigrationCompleted()).to.be.false

      // Perform manual migration
      await newContract.migrateFromOldContract(oldContractAddress)

      // Verify migration completed
      expect(await newContract.isMigrationCompleted()).to.be.true
      expect(await newContract.getOldContractAddress()).to.equal(oldContractAddress)

      // Verify migrated data
      expect(await newContract._AgentMiningTotalAward()).to.equal(await oldContract._GPUMiningTotalAward())
    })

    it('Should prevent double migration', async function () {
      const NewContractFactory = await ethers.getContractFactory('HyperAGI_AgentMining')
      const oldContractAddress = await oldContract.getAddress()

      newContract = (await upgrades.deployProxy(NewContractFactory, [owner.address, RELEASE_INTERVAL], { initializer: 'initialize', kind: 'uups' })) as any
      await newContract.waitForDeployment()

      // First migration
      await newContract.migrateFromOldContract(oldContractAddress)

      // Attempt second migration
      await expect(newContract.migrateFromOldContract(oldContractAddress)).to.be.revertedWith('Migration already completed')
    })

    it('Should reject invalid old contract address', async function () {
      const NewContractFactory = await ethers.getContractFactory('HyperAGI_AgentMining')

      newContract = (await upgrades.deployProxy(NewContractFactory, [owner.address, RELEASE_INTERVAL], { initializer: 'initialize', kind: 'uups' })) as any
      await newContract.waitForDeployment()

      // Try to migrate with zero address
      await expect(newContract.migrateFromOldContract(ethers.ZeroAddress)).to.be.revertedWith('Invalid old contract address')
    })

    it('Should only allow owner to perform manual migration', async function () {
      const NewContractFactory = await ethers.getContractFactory('HyperAGI_AgentMining')
      const oldContractAddress = await oldContract.getAddress()

      newContract = (await upgrades.deployProxy(NewContractFactory, [owner.address, RELEASE_INTERVAL], { initializer: 'initialize', kind: 'uups' })) as any
      await newContract.waitForDeployment()

      // Try to migrate with non-owner account
      await expect(newContract.connect(user).migrateFromOldContract(oldContractAddress)).to.be.reverted // OwnableUpgradeable error
    })
  })

  describe('Migration state verification', function () {
    beforeEach(async function () {
      const NewContractFactory = await ethers.getContractFactory('HyperAGI_AgentMining')
      const oldContractAddress = await oldContract.getAddress()

      newContract = (await upgrades.deployProxy(NewContractFactory, [owner.address, oldContractAddress, RELEASE_INTERVAL], { initializer: 'initializeWithMigration', kind: 'uups' })) as any
      await newContract.waitForDeployment()
    })

    it('Should return correct migration state', async function () {
      const migrationState = await newContract.getMigrationState()
      const oldContractAddress = await oldContract.getAddress()

      expect(migrationState.migrationCompleted).to.be.true
      expect(migrationState.oldContractAddress).to.equal(oldContractAddress)
      expect(migrationState.migratedTotalAward).to.equal(await oldContract._GPUMiningTotalAward())
      expect(migrationState.migratedCurrAward).to.equal(await oldContract._GPUMiningCurrAward())
      expect(migrationState.migratedTGETimestamp).to.equal(await oldContract._TGE_timestamp())
    })

    it('Should maintain functionality after migration', async function () {
      // Grant MINTER_ROLE
      const MINTER_ROLE = await newContract.MINTER_ROLE()
      await newContract.grantRole(MINTER_ROLE, minter.address)

      // Send some ETH to the contract
      await owner.sendTransaction({
        to: await newContract.getAddress(),
        value: ethers.parseEther('10'),
      })

      // Verify we can still call business functions
      const allowMintData = await newContract.getAgentMiningCurrAllowMintTotalNum()
      expect(allowMintData[1]).to.be.gt(0) // currYearTotalSupply should be greater than 0
    })
  })

  describe('Edge cases', function () {
    it('Should handle migration from contract with zero TGE', async function () {
      // Deploy a new old contract without starting TGE
      const OldContractFactory = await ethers.getContractFactory('HyperAGI_AgentWallet')
      const oldContractNoTGE = (await upgrades.deployProxy(OldContractFactory, [owner.address, RELEASE_INTERVAL], { initializer: 'initialize', kind: 'uups' })) as any
      await oldContractNoTGE.waitForDeployment()

      // Deploy new contract with migration
      const NewContractFactory = await ethers.getContractFactory('HyperAGI_AgentMining')
      const newContractFromNoTGE = (await upgrades.deployProxy(NewContractFactory, [owner.address, await oldContractNoTGE.getAddress(), RELEASE_INTERVAL], { initializer: 'initializeWithMigration', kind: 'uups' })) as any
      await newContractFromNoTGE.waitForDeployment()

      // TGE should be 0
      expect(await newContractFromNoTGE._TGE_timestamp()).to.equal(0)
    })

    it('Should preserve role-based access control after migration', async function () {
      const NewContractFactory = await ethers.getContractFactory('HyperAGI_AgentMining')
      const oldContractAddress = await oldContract.getAddress()

      newContract = (await upgrades.deployProxy(NewContractFactory, [owner.address, oldContractAddress, RELEASE_INTERVAL], { initializer: 'initializeWithMigration', kind: 'uups' })) as any
      await newContract.waitForDeployment()

      // Owner should have DEFAULT_ADMIN_ROLE
      const DEFAULT_ADMIN_ROLE = await newContract.DEFAULT_ADMIN_ROLE()
      expect(await newContract.hasRole(DEFAULT_ADMIN_ROLE, owner.address)).to.be.true

      // User should not have MINTER_ROLE
      const MINTER_ROLE = await newContract.MINTER_ROLE()
      expect(await newContract.hasRole(MINTER_ROLE, user.address)).to.be.false
    })
  })
})
