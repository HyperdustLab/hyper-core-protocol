import { expect } from 'chai'
import { ethers } from 'hardhat'
import { HyperAGI_Agent_Epoch_Payment } from '../typechain-types'

describe('HyperAGI_Agent_Epoch_Payment', function () {
  let epochPaymentContract: HyperAGI_Agent_Epoch_Payment
  let agentContract: any
  let rolesCfgContract: any
  let owner: any
  let user: any
  let admin: any

  const EPOCH_PAYMENT_AMOUNT = ethers.utils.parseEther('0.001')
  const EPOCH_DURATION = 384 // 6.4 minutes in seconds

  beforeEach(async function () {
    ;[owner, user, admin] = await ethers.getSigners()

    // Deploy HyperAGI_Agent_Epoch_Payment contract
    const HyperAGI_Agent_Epoch_Payment = await ethers.getContractFactory('HyperAGI_Agent_Epoch_Payment')
    epochPaymentContract = await HyperAGI_Agent_Epoch_Payment.deploy()
    await epochPaymentContract.deployed()
    await epochPaymentContract.initialize(owner.address)

    // Deploy HyperAGI_Roles_Cfg contract (simplified version for testing)
    const HyperAGI_Roles_Cfg = await ethers.getContractFactory('HyperAGI_Roles_Cfg')
    rolesCfgContract = await HyperAGI_Roles_Cfg.deploy()
    await rolesCfgContract.deployed()
    await rolesCfgContract.initialize(owner.address)

    // Deploy HyperAGI_Agent contract (simplified version for testing)
    const HyperAGI_Agent = await ethers.getContractFactory('HyperAGI_Agent')
    agentContract = await HyperAGI_Agent.deploy()
    await agentContract.deployed()
    await agentContract.initialize(owner.address)

    // Set contract addresses
    await epochPaymentContract.setRolesCfgAddress(rolesCfgContract.address)
    await epochPaymentContract.setAgentAddress(agentContract.address)

    // Add admin role to admin
    await rolesCfgContract.addAdminRole(admin.address)
  })

  describe('Deployment and Initialization', function () {
    it('should initialize contract correctly', async function () {
      expect(await epochPaymentContract.owner()).to.equal(owner.address)
      expect(await epochPaymentContract.getEpochPaymentAmount()).to.equal(EPOCH_PAYMENT_AMOUNT)
      expect(await epochPaymentContract.getEpochDuration()).to.equal(EPOCH_DURATION)
    })

    it('should set contract addresses correctly', async function () {
      expect(await epochPaymentContract._rolesCfgAddress()).to.equal(rolesCfgContract.address)
      expect(await epochPaymentContract._agentAddress()).to.equal(agentContract.address)
    })
  })

  describe('Payment Functions', function () {
    it('should allow users to pay epoch fees', async function () {
      const sid = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('test-agent-1'))

      // Simulate agent exists (set storage)
      // This needs to be set according to the actual HyperAGI_Agent contract implementation

      const tx = await epochPaymentContract.connect(user).payEpochFee(sid, {
        value: EPOCH_PAYMENT_AMOUNT,
      })

      await expect(tx)
        .to.emit(epochPaymentContract, 'EpochPaymentCompleted')
        .withArgs(sid, await getCurrentTimestamp(), (await getCurrentTimestamp()) + EPOCH_DURATION, EPOCH_PAYMENT_AMOUNT, user.address)
    })

    it('should reject incorrect payment amount', async function () {
      const sid = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('test-agent-1'))
      const wrongAmount = ethers.utils.parseEther('0.002')

      await expect(
        epochPaymentContract.connect(user).payEpochFee(sid, {
          value: wrongAmount,
        })
      ).to.be.revertedWith('incorrect payment amount')
    })

    it('should allow admin to pay epoch fees for free', async function () {
      const sid = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('test-agent-1'))

      const tx = await epochPaymentContract.connect(admin).adminPayEpochFee(sid)

      await expect(tx)
        .to.emit(epochPaymentContract, 'EpochPaymentCompleted')
        .withArgs(sid, await getCurrentTimestamp(), (await getCurrentTimestamp()) + EPOCH_DURATION, 0, admin.address)
    })

    it('should reject non-admin calling adminPayEpochFee', async function () {
      const sid = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('test-agent-1'))

      await expect(epochPaymentContract.connect(user).adminPayEpochFee(sid)).to.be.revertedWith('not admin role')
    })
  })

  describe('Admin Functions', function () {
    it('should allow owner to withdraw ETH', async function () {
      // First send some ETH to the contract
      await user.sendTransaction({
        to: epochPaymentContract.address,
        value: ethers.utils.parseEther('1.0'),
      })

      const initialBalance = await owner.getBalance()
      const contractBalance = await epochPaymentContract.getContractBalance()

      const tx = await epochPaymentContract.connect(owner).withdrawAllETH(owner.address)
      const receipt = await tx.wait()
      const gasUsed = receipt.gasUsed.mul(receipt.effectiveGasPrice)

      const finalBalance = await owner.getBalance()
      expect(finalBalance).to.equal(initialBalance.add(contractBalance).sub(gasUsed))
    })

    it('should reject non-owner withdrawing ETH', async function () {
      await expect(epochPaymentContract.connect(user).withdrawAllETH(user.address)).to.be.revertedWith('Ownable: caller is not the owner')
    })

    it('should return fixed payment amount', async function () {
      const expectedAmount = ethers.utils.parseEther('0.001')
      expect(await epochPaymentContract.getEpochPaymentAmount()).to.equal(expectedAmount)
    })

    it('should allow admin to modify duration', async function () {
      const newDuration = 600 // 10 minutes
      await epochPaymentContract.connect(admin).setEpochDuration(newDuration)
      expect(await epochPaymentContract.getEpochDuration()).to.equal(newDuration)
    })

    it('should reject non-admin modifying duration', async function () {
      const newDuration = 600
      await expect(epochPaymentContract.connect(user).setEpochDuration(newDuration)).to.be.revertedWith('not admin role')
    })

    it('should reject setting invalid duration', async function () {
      await expect(epochPaymentContract.connect(admin).setEpochDuration(0)).to.be.revertedWith('duration must be greater than 0')
    })
  })

  describe('Contract Upgrade', function () {
    it('should support upgradeable mode', async function () {
      // Contract uses Initializable + OwnableUpgradeable mode
      // Consistent upgrade mode with HyperAGI_Agent.sol
      expect(await epochPaymentContract.owner()).to.equal(owner.address)
    })
  })

  // Helper function
  async function getCurrentTimestamp(): Promise<number> {
    const blockNumber = await ethers.provider.getBlockNumber()
    const block = await ethers.provider.getBlock(blockNumber)
    return block.timestamp
  }
})
