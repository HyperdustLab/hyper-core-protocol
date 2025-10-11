/** @format */

import { ethers, run, upgrades } from 'hardhat'

async function main() {
  const contract = await ethers.getContractFactory('HyperAGI_AgentMining')
  const instance = await upgrades.deployProxy(contract, [process.env.ADMIN_Wallet_Address, 60 * 60 * 24 * 365])
  await instance.waitForDeployment()

  console.info('contractFactory address:', instance.target)

  // Verify contract
  const implementationAddress = await upgrades.erc1967.getImplementationAddress(instance.target)
  console.log('Implementation contract address:', implementationAddress)

  try {
    await run('verify:verify', {
      address: implementationAddress,
      constructorArguments: [],
    })
    console.log('Contract verification successful')
  } catch (error) {
    console.warn('Contract verification failed:', error)
  }
}

// We recommend this pattern to be able to use async/await everywhere q
// and properly handle errors.
main().catch(error => {
  console.error(error)
  process.exitCode = 1
})
