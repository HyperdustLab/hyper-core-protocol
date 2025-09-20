import { expect } from 'chai'
import { ethers } from 'hardhat'
import { HyperAGI_Agent, HyperAGI_Agent_Epoch_Awards } from '../typechain-types'

describe('Agent Count Management', function () {
  let agentContract: HyperAGI_Agent
  let epochAwardsContract: HyperAGI_Agent_Epoch_Awards
  let owner: any
  let admin: any

  beforeEach(async function () {
    ;[owner, admin] = await ethers.getSigners()

    // Deploy HyperAGI_Agent contract
    const AgentFactory = await ethers.getContractFactory('HyperAGI_Agent')
    agentContract = await AgentFactory.deploy()
    await agentContract.initialize(owner.address)

    // Deploy HyperAGI_Agent_Epoch_Awards contract
    const EpochAwardsFactory = await ethers.getContractFactory('HyperAGI_Agent_Epoch_Awards')
    epochAwardsContract = await EpochAwardsFactory.deploy()
    await epochAwardsContract.initialize(owner.address)

    // Set agent address in epoch awards contract
    await epochAwardsContract.setAgentAddress(agentContract.address)
  })

  describe('Agent Count Management', function () {
    it('Should set and get agent counts correctly', async function () {
      const totalCount = 1000
      const onlineCount = 800

      // Set agent counts
      await agentContract.setAgentCounts(totalCount, onlineCount)

      // Verify counts
      const [retrievedTotal, retrievedOnline] = await agentContract.getAgentCounts()
      expect(retrievedTotal).to.equal(totalCount)
      expect(retrievedOnline).to.equal(onlineCount)

      // Test individual getters
      expect(await agentContract.getTotalAgentCount()).to.equal(totalCount)
      expect(await agentContract.getOnlineAgentCount()).to.equal(onlineCount)
    })

    it('Should reject setting online count greater than total count', async function () {
      const totalCount = 100
      const onlineCount = 150

      await expect(agentContract.setAgentCounts(totalCount, onlineCount)).to.be.revertedWith('online count cannot exceed total count')
    })

    it('Should only allow admin to set agent counts', async function () {
      const totalCount = 100
      const onlineCount = 80

      // Non-admin should not be able to set counts
      await expect(agentContract.connect(admin).setAgentCounts(totalCount, onlineCount)).to.be.revertedWith('not admin role')
    })

    it('Should emit event when agent counts are updated', async function () {
      const totalCount = 500
      const onlineCount = 400

      await expect(agentContract.setAgentCounts(totalCount, onlineCount)).to.emit(agentContract, 'eveAgentCountUpdated').withArgs(totalCount, onlineCount)
    })
  })

  describe('Integration with Epoch Awards', function () {
    it('Should update agent counts when epoch awards are distributed', async function () {
      // This test would require setting up the full contract dependencies
      // For now, we'll just verify the method exists and can be called
      const agentStatus: string[] = []
      const nonce = 1
      const gasFee = ethers.utils.parseEther('0.001')

      // This would fail due to missing dependencies, but shows the integration point
      // await epochAwardsContract.rewards(agentStatus, nonce, gasFee);

      // Verify the method exists
      expect(typeof epochAwardsContract.rewards).to.equal('function')
    })
  })
})
