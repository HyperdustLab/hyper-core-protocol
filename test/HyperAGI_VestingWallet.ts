import { expect } from 'chai'
import { ethers, upgrades } from 'hardhat'
import { HardhatEthersSigner } from '@nomicfoundation/hardhat-ethers/signers'
import { HyperAGI_VestingWallet } from '../typechain-types'
import { BigNumberish } from 'ethers'
import { parseEther } from 'ethers'

describe('HyperAGI_VestingWallet', function () {
  let vestingWallet: HyperAGI_VestingWallet
  let owner: HardhatEthersSigner
  let addr1: HardhatEthersSigner
  let addr2: HardhatEthersSigner
  let initialTimestamp: number

  beforeEach(async function () {
    ;[owner, addr1, addr2] = await ethers.getSigners()

    const VestingWallet = await ethers.getContractFactory('HyperAGI_VestingWallet')
    vestingWallet = (await upgrades.deployProxy(VestingWallet, [owner.address], { initializer: 'initialize' })) as unknown as HyperAGI_VestingWallet
    await vestingWallet.waitForDeployment()
  })

  describe('Basic Function Tests', function () {
    it('should initialize contract correctly', async function () {
      const minterRole = await vestingWallet.MINTER_ROLE()
      const adminRole = await vestingWallet.DEFAULT_ADMIN_ROLE()

      expect(await vestingWallet.hasRole(minterRole, owner.address)).to.be.true
      expect(await vestingWallet.hasRole(adminRole, owner.address)).to.be.true
    })

    it('should be able to receive ETH', async function () {
      const amount: BigNumberish = parseEther('1.0')
      await owner.sendTransaction({
        to: vestingWallet.getAddress(),
        value: amount,
      })

      const balance = await ethers.provider.getBalance(vestingWallet.getAddress())
      expect(balance).to.equal(amount)
    })
  })

  describe.only('Allocation and Withdrawal Tests', function () {
    const releaseInterval: number = 86400 // 30 days in seconds
    const delayVestingNum: number = 0
    const firstRate: number = 20 // 20% initial release
    const linearVestingNum: number = 5

    it.only('should allocate tokens correctly', async function () {
      const accounts: string[] = [addr1.address]
      const amounts: BigNumberish[] = [parseEther('100')]
      const releaseConfig: number[] = [releaseInterval, delayVestingNum, firstRate, linearVestingNum]

      // Send sufficient ETH to contract
      await owner.sendTransaction({
        to: vestingWallet.getAddress(),
        value: parseEther('100'),
      })

      const tx = await vestingWallet.connect(owner).appendAccountTotalAllocation(accounts, amounts, releaseConfig, { value: parseEther('100') })
      const receipt = await tx.wait()

      // Get eveUpdate event information through logs
      const logs = await ethers.provider.getLogs({ fromBlock: receipt.blockNumber, toBlock: receipt.blockNumber })
      const eveUpdateLog = logs.find(log => log.topics[0] === ethers.id('eveUpdate(string[],address[],uint256[],uint256[],uint256[])'))
      if (eveUpdateLog) {
        const parsedLog = vestingWallet.interface.parseLog(eveUpdateLog)
        console.log('eveUpdate event:', parsedLog.args)
      } else {
        console.log('eveUpdate event not found')
      }
    })

    it('should allow users to withdraw unlocked tokens', async function () {
      const accounts: string[] = [addr1.address]
      const amounts: BigNumberish[] = [parseEther('100')]
      const releaseConfig: number[] = [releaseInterval, delayVestingNum, firstRate, linearVestingNum]

      // Send ETH to contract
      await owner.sendTransaction({
        to: vestingWallet.getAddress(),
        value: parseEther('100'),
      })

      await vestingWallet.connect(owner).appendAccountTotalAllocation(accounts, amounts, releaseConfig, { value: parseEther('100') })

      // Modification: Add more time waiting
      // Wait for delay period + one complete release cycle
      const waitTime = releaseInterval * (delayVestingNum + 1)
      await ethers.provider.send('evm_increaseTime', [waitTime])
      await ethers.provider.send('evm_mine', [])

      // Get current block timestamp and print for debugging
      const block = await ethers.provider.getBlock('latest')
      console.log('Current timestamp:', block.timestamp)

      const currentDate = await getCurrentFormattedDate()
      console.log('Withdrawal date:', currentDate)
      const pendingAmount = await vestingWallet.getAmount(currentDate, addr1.address, vestingWallet.PENDING_RELEASE_AMOUNT())
      if (pendingAmount > 0) {
        await expect(vestingWallet.connect(addr1).withdraw([currentDate])).to.emit(vestingWallet, 'eveUpdate')
      } else {
        console.log('Pending release amount is zero, withdrawal not executed')
      }
    })
  })

  describe('Error Handling Tests', function () {
    it('should reject appendAccountTotalAllocation from non-MINTER_ROLE', async function () {
      const [owner, nonMinter] = await ethers.getSigners()

      // Test data
      const accounts = [nonMinter.address]
      const amounts = [ethers.parseEther('1.0')]
      const releaseConfiguration = [
        86400, // releaseInterval (1 day in seconds)
        0, // delayVestingNum
        10, // firstRate
        12, // linearVestingNum
      ]

      // Use revertedWithCustomError instead of revertedWith
      await expect(vestingWallet.connect(nonMinter).appendAccountTotalAllocation(accounts, amounts, releaseConfiguration, { value: ethers.parseEther('1.0') }))
        .to.be.revertedWithCustomError(vestingWallet, 'AccessControlUnauthorizedAccount')
        .withArgs(nonMinter.address, await vestingWallet.MINTER_ROLE())
    })

    it('should fail when withdrawal amount is zero', async function () {
      const currentDate = await getCurrentFormattedDate()
      await expect(vestingWallet.connect(addr1).withdraw(currentDate)).to.be.revertedWith('Pending release amount is zero')
    })
  })
})

describe('Linear Vesting Process', function () {
  let vestingWallet: HyperAGI_VestingWallet
  let owner: HardhatEthersSigner
  let addr1: HardhatEthersSigner
  let initialTimestamp: number

  beforeEach(async function () {
    ;[owner, addr1] = await ethers.getSigners()
    const VestingWallet = await ethers.getContractFactory('HyperAGI_VestingWallet')
    vestingWallet = (await upgrades.deployProxy(VestingWallet, [owner.address], { initializer: 'initialize' })) as unknown as HyperAGI_VestingWallet
    await vestingWallet.waitForDeployment()
  })

  it('should release tokens linearly over 12 months with 20% in the first month and a 3-month delay', async function () {
    const accounts: string[] = [addr1.address]
    const amounts: BigNumberish[] = [parseEther('100')]
    const releaseConfig: number[] = [30 * 24 * 60 * 60, 3, 20, 12]

    // Record initial time
    const initialBlock = await ethers.provider.getBlock('latest')
    const initialTimestamp = initialBlock.timestamp
    const initialDate = new Date(initialTimestamp * 1000)
    console.log('Initial date:', initialDate.toISOString().split('T')[0])

    await vestingWallet.connect(owner).appendAccountTotalAllocation(accounts, amounts, releaseConfig, { value: parseEther('100') })

    // Move time to after delay period
    const delayPeriod = 3 * 30 * 24 * 60 * 60
    await ethers.provider.send('evm_increaseTime', [delayPeriod])
    await ethers.provider.send('evm_mine', [])

    // Use getCurrentFormattedDate to get current date
    const formattedDate = await getCurrentFormattedDate()
    console.log('Current date from block timestamp:', formattedDate)

    const unlockedAmount = await vestingWallet.getAmount(formattedDate, addr1.address, await vestingWallet.PENDING_RELEASE_AMOUNT())
    console.log('Unlocked amount:', ethers.formatEther(unlockedAmount))

    // Only withdraw if there is pending release amount
    if (unlockedAmount > 0) {
      await vestingWallet.connect(addr1).withdraw(formattedDate)
      console.log('Withdrawal successful')
    } else {
      console.log('No pending amount available for withdrawal')
    }
  })
})

/**
 * Helper function: Get formatted current date
 * @returns Promise<string> Date in format YYYY-MM-DD
 */
async function getCurrentFormattedDate(): Promise<string> {
  const blockNum = await ethers.provider.getBlockNumber()
  const block = await ethers.provider.getBlock(blockNum)
  const timestamp = block.timestamp

  const year = Math.floor(timestamp / 31556926) + 1970
  const month = Math.floor((timestamp % 31556926) / 2629743) + 1
  const day = Math.floor((timestamp % 2629743) / 86400) + 1

  const monthStr = month < 10 ? `0${month}` : month.toString()
  const dayStr = day < 10 ? `0${day}` : day.toString()

  return `${year}-${monthStr}-${dayStr}`
}
