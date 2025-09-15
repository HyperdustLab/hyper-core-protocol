/** @format */

import { ethers, run, upgrades } from 'hardhat'

async function main() {
  console.info('Starting deployment of HyperAGI_Foundation_Vesting contract...')

  const contract = await ethers.getContractFactory('HyperAGI_Foundation_Vesting')

  console.info('Contract factory obtained successfully')

  const instance = await upgrades.deployProxy(contract, [process.env.ADMIN_Wallet_Address])

  console.info('Proxy contract deployment completed')

  await instance.waitForDeployment()

  console.info('Waiting for deployment to complete')

  console.info('HyperAGI_Foundation_Vesting contract address:', instance.target)

  // Get implementation contract address
  const implementationAddress = await upgrades.erc1967.getImplementationAddress(instance.target)

  console.info('Implementation contract address:', implementationAddress)

  // Verify contract
  try {
    await run('verify:verify', {
      address: implementationAddress,
      constructorArguments: [],
    })
    console.info('Contract verification successful')
  } catch (error) {
    console.warn('Contract verification failed:', error)
  }
}

// Recommended pattern for using async/await anywhere
// and properly handling errors
main().catch(error => {
  console.error(error)
  process.exitCode = 1
})
