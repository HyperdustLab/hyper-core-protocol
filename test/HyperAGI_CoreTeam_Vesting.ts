/** @format */

import { expect } from 'chai'
import { ethers, upgrades } from 'hardhat'
import { HardhatEthersSigner } from '@nomicfoundation/hardhat-ethers/signers'
import { HyperAGI_CoreTeam_Vesting } from '../typechain-types'
import { parseEther, formatEther } from 'ethers'

describe('HyperAGI_CoreTeam_Vesting', function () {
  let vestingContract: HyperAGI_CoreTeam_Vesting
  let owner: HardhatEthersSigner
  let beneficiary: HardhatEthersSigner
  let manager: HardhatEthersSigner
  let other: HardhatEthersSigner

  const VESTING_AMOUNT = parseEther('0.1') // 1,000 HYPT
  const VESTING_PERCENTAGE = 20 // 20%
  const VESTING_DURATION = 36 // 36 months
  const SECONDS_PER_MONTH = 30 * 24 * 60 * 60 // 30 days per month

  beforeEach(async function () {
    ;[owner, beneficiary, manager, other] = await ethers.getSigners()

    const VestingContract = await ethers.getContractFactory('HyperAGI_CoreTeam_Vesting')
    vestingContract = (await upgrades.deployProxy(VestingContract, [owner.address], {
      initializer: 'initialize',
    })) as unknown as HyperAGI_CoreTeam_Vesting
    await vestingContract.waitForDeployment()
  })

  describe('释放金额测试', function () {
    beforeEach(async function () {
      // 设置受益人
      await vestingContract.setBeneficiary(beneficiary.address)

      // 存入HYPT
      await vestingContract.depositHYPT({ value: VESTING_AMOUNT })

      // 开始vesting
      await vestingContract.startVesting(VESTING_AMOUNT)
    })

    it('应该正确计算1个周期的释放金额', async function () {
      // 等待1个周期（600秒）
      await ethers.provider.send('evm_increaseTime', [600])
      await ethers.provider.send('evm_mine', [])

      const releasableAmount = await vestingContract.getCurrentReleasableAmount()
      const expectedAmount = (VESTING_AMOUNT * BigInt(VESTING_PERCENTAGE) * BigInt(600)) / (BigInt(100) * BigInt(36) * BigInt(600))

      console.log('1个周期释放金额:', formatEther(releasableAmount))
      console.log('预期释放金额:', formatEther(expectedAmount))

      expect(releasableAmount).to.be.closeTo(expectedAmount, parseEther('0.001'))
    })

    it('应该正确计算5个周期的释放金额', async function () {
      // 等待5个周期（5 * 600 = 3000秒）
      await ethers.provider.send('evm_increaseTime', [3600])
      await ethers.provider.send('evm_mine', [])

      const releasableAmount = await vestingContract.getCurrentReleasableAmount()
      const expectedAmount = (VESTING_AMOUNT * BigInt(VESTING_PERCENTAGE) * BigInt(3000)) / (BigInt(100) * BigInt(36) * BigInt(600))

      console.log('5个周期释放金额:', formatEther(releasableAmount))
      console.log('预期释放金额:', formatEther(expectedAmount))

      expect(releasableAmount).to.be.closeTo(expectedAmount, parseEther('0.001'))
    })

    it('应该能够成功释放1个周期的HYPT', async function () {
      // 等待1个周期
      await ethers.provider.send('evm_increaseTime', [600])
      await ethers.provider.send('evm_mine', [])

      const initialBalance = await ethers.provider.getBalance(beneficiary.address)
      const releasableAmount = await vestingContract.getCurrentReleasableAmount()

      // 执行释放
      await vestingContract.connect(beneficiary).release()

      const finalBalance = await ethers.provider.getBalance(beneficiary.address)
      const releasedAmount = finalBalance - initialBalance

      console.log('实际释放金额:', formatEther(releasedAmount))
      console.log('可释放金额:', formatEther(releasableAmount))

      expect(releasedAmount).to.equal(releasableAmount)
    })

    it('应该能够成功释放5个周期的HYPT', async function () {
      // 等待5个周期
      await ethers.provider.send('evm_increaseTime', [3000])
      await ethers.provider.send('evm_mine', [])

      const initialBalance = await ethers.provider.getBalance(beneficiary.address)
      const releasableAmount = await vestingContract.getCurrentReleasableAmount()

      // 执行释放
      await vestingContract.connect(beneficiary).release()

      const finalBalance = await ethers.provider.getBalance(beneficiary.address)
      const releasedAmount = finalBalance - initialBalance

      console.log('实际释放金额:', formatEther(releasedAmount))
      console.log('可释放金额:', formatEther(releasableAmount))

      expect(releasedAmount).to.equal(releasableAmount)
    })

    it('应该显示vesting信息', async function () {
      const vestingInfo = await vestingContract.getVestingInfo()
      const beneficiaryInfo = await vestingContract.getBeneficiaryInfo()

      console.log('Vesting信息:')
      console.log('- 释放百分比:', vestingInfo[0].toString(), '%')
      console.log('- 释放周期:', vestingInfo[1].toString(), '个月')
      console.log('- 总金额:', formatEther(vestingInfo[2]))
      console.log('- 已释放:', formatEther(vestingInfo[4]))
      console.log('- 剩余金额:', formatEther(vestingInfo[5]))

      console.log('受益人信息:')
      console.log('- 受益人地址:', beneficiaryInfo[0])
      console.log('- 分配份额:', formatEther(beneficiaryInfo[1]))
      console.log('- 已释放:', formatEther(beneficiaryInfo[2]))
      console.log('- 可释放:', formatEther(beneficiaryInfo[3]))
      console.log('- 剩余:', formatEther(beneficiaryInfo[4]))
    })
  })
})
