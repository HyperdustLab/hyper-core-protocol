/** @format */

import { expect } from 'chai'
import { ethers, upgrades } from 'hardhat'

describe('HyperAGI_CoreTeam_Vesting 基础功能测试', function () {
  let vestingContract: any
  let owner: any
  let beneficiary: any
  let other: any

  beforeEach(async function () {
    ;[owner, beneficiary, other] = await ethers.getSigners()

    const VestingContract = await ethers.getContractFactory('HyperAGI_CoreTeam_Vesting')
    vestingContract = await upgrades.deployProxy(VestingContract, [owner.address], { 
      initializer: 'initialize' 
    })
    await vestingContract.waitForDeployment()
  })

  it('应该正确初始化合约', async function () {
    console.log('测试合约初始化...')
    expect(await vestingContract.owner()).to.equal(owner.address)
    console.log('✓ 所有者设置正确')
    
    const hasAdminRole = await vestingContract.hasRole(await vestingContract.DEFAULT_ADMIN_ROLE(), owner.address)
    expect(hasAdminRole).to.be.true
    console.log('✓ 管理员角色设置正确')
  })

  it('应该设置正确的常量值', async function () {
    console.log('测试常量值...')
    expect(await vestingContract.vestingPercentage()).to.equal(20)
    console.log('✓ vesting百分比正确')
    
    expect(await vestingContract.vestingDuration()).to.equal(36)
    console.log('✓ vesting持续时间正确')
  })

  it('应该能够接收HYPT', async function () {
    console.log('测试接收HYPT...')
    const amount = ethers.parseEther('100')
    
    await owner.sendTransaction({
      to: await vestingContract.getAddress(),
      value: amount
    })

    const balance = await ethers.provider.getBalance(await vestingContract.getAddress())
    expect(balance).to.equal(amount)
    console.log('✓ 成功接收HYPT')
  })

  it('应该允许管理员设置受益人', async function () {
    console.log('测试设置受益人...')
    
    const tx = await vestingContract.connect(owner).setBeneficiary(beneficiary.address)
    await tx.wait()
    
    expect(await vestingContract.beneficiary()).to.equal(beneficiary.address)
    console.log('✓ 受益人设置成功')
  })

  it('应该拒绝非管理员设置受益人', async function () {
    console.log('测试权限控制...')
    
    await expect(vestingContract.connect(other).setBeneficiary(beneficiary.address))
      .to.be.revertedWithCustomError(vestingContract, 'AccessControlUnauthorizedAccount')
    console.log('✓ 权限控制正确')
  })

  it('应该允许管理员启动vesting', async function () {
    console.log('测试启动vesting...')
    
    await vestingContract.connect(owner).setBeneficiary(beneficiary.address)
    
    const vestingAmount = ethers.parseEther('1000000')
    const tx = await vestingContract.connect(owner).startVesting(vestingAmount)
    await tx.wait()

    expect(await vestingContract.totalVestingAmount()).to.equal(vestingAmount)
    expect(await vestingContract.vestingStartTime()).to.be.greaterThan(0)
    console.log('✓ vesting启动成功')
  })

  it('应该正确计算可释放金额', async function () {
    console.log('测试可释放金额计算...')
    
    await vestingContract.connect(owner).setBeneficiary(beneficiary.address)
    await vestingContract.connect(owner).startVesting(ethers.parseEther('1000000'))

    const releasableAmount = await vestingContract.calculateReleasableAmount()
    expect(releasableAmount).to.equal(0) // 刚开始时应该为0
    console.log('✓ 可释放金额计算正确')
  })

  it('应该正确返回vesting信息', async function () {
    console.log('测试vesting信息查询...')
    
    await vestingContract.connect(owner).setBeneficiary(beneficiary.address)
    const vestingAmount = ethers.parseEther('1000000')
    await vestingContract.connect(owner).startVesting(vestingAmount)

    const vestingInfo = await vestingContract.getVestingInfo()
    
    expect(vestingInfo[0]).to.equal(20) // vestingPercentage
    expect(vestingInfo[1]).to.equal(36) // vestingDuration
    expect(vestingInfo[2]).to.equal(vestingAmount) // totalAmount
    expect(vestingInfo[3]).to.be.greaterThan(0) // startTime
    console.log('✓ vesting信息查询正确')
  })

  it('应该允许所有者存入HYPT', async function () {
    console.log('测试存入HYPT...')
    
    const amount = ethers.parseEther('100')
    
    await expect(vestingContract.connect(owner).depositHYPT({ value: amount }))
      .to.not.be.reverted

    expect(await vestingContract.getContractBalance()).to.equal(amount)
    console.log('✓ 存入HYPT成功')
  })
})
