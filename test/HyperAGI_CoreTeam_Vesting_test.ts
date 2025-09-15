/** @format */

import { expect } from 'chai'
import { ethers, upgrades } from 'hardhat'
import { Contract } from 'ethers'

describe('HyperAGI_CoreTeam_Vesting_Test', () => {
  describe('sendRequest', () => {
    it('sendRequest', async () => {
      const accounts = await ethers.getSigners()

      const contract = await ethers.getContractAt('HyperAGI_CoreTeam_Vesting', '0x1e697fb7e32Da23b2A2c2B2773BEF33fCD81f9b0')

      await contract.release()
    })
  })
})
