/** @format */

import { ethers, run, upgrades } from 'hardhat'

async function main() {
  const abiCoder = new ethers.AbiCoder()

  const contractName = 'Tagtal Orbit Token'
  const contractSymbol = 'Tagtal'

  const contract = await ethers.deployContract('HyperAGI_20', [contractName, contractSymbol])
  await contract.waitForDeployment()

  console.info('contractFactory address:', contract.target)

  // Wait for block confirmations before verification
  console.info('Waiting for block confirmations...')
  await new Promise(resolve => setTimeout(resolve, 10000))

  // Source code verification
  try {
    console.info('Starting source code verification...')
    await run('verify:verify', {
      address: contract.target,
      constructorArguments: [contractName, contractSymbol],
    })
    console.info('✅ Source code verification successful!')
  } catch (error: any) {
    console.error('❌ Source code verification failed:', error.message)
    console.info('Please verify contract manually at:', contract.target)
  }
}

// We recommend this pattern to be able to use async/await everywhere q
// and properly handle errors.
main().catch(error => {
  console.error(error)
  process.exitCode = 1
})
