/** @format */

import { ethers, run, upgrades } from 'hardhat'

async function main() {
  console.info('Starting deployment of HyperAGI_CoreTeam_Vesting contract...')

  // const contract = await ethers.getContractFactory('HyperAGI_CoreTeam_Vesting_Dev_Test')

  // console.info('Contract factory obtained successfully')

  // const instance = await upgrades.deployProxy(contract, ['0xc619a8e80f485f5cccb87041bad2d2b0acc843e2', '0xd03E48d335959af29e560D66f9cC0D9095A8dE8d'])

  // console.info('Proxy contract deployment completed')

  // await instance.waitForDeployment()

  // console.info('Waiting for deployment to complete')

  // console.info('HyperAGI_CoreTeam_Vesting contract address:', instance.target)

  // Get implementation contract address
  // const implementationAddress = await upgrades.erc1967.getImplementationAddress(instance.target)
  const implementationAddress = await upgrades.erc1967.getImplementationAddress('0xddDb324507496e7f9B3d7c43d3De59f2C84a8b9F')

  console.info('Implementation contract address:', implementationAddress)

  // Wait for blockchain to index the contract
  console.log('Waiting 30 seconds for blockchain to index the contract...')
  await new Promise(resolve => setTimeout(resolve, 30000))

  // Method 1: Force verification
  try {
    console.log('Attempting force verification...')
    await run('verify:verify', {
      address: implementationAddress,
      constructorArguments: [],
      force: true, // Force verification, even if contract is partially verified
    })
    console.log('✅ Force verification successful!')
    return
  } catch (error) {
    console.error('❌ Force verification failed:', error.message)
  }

  // Method 2: Normal verification
  try {
    console.log('Attempting normal verification...')
    await run('verify:verify', {
      address: implementationAddress,
      constructorArguments: [],
    })
    console.log('✅ Normal verification successful!')
    return
  } catch (error) {
    console.error('❌ Normal verification failed:', error.message)
  }

  // Method 3: Command line verification
  console.log('Attempting command line verification...')
  try {
    const { exec } = require('child_process')
    const command = `npx hardhat verify --network arbitrumMainnet --force ${implementationAddress}`
    console.log('Executing command:', command)

    exec(command, (error, stdout, stderr) => {
      if (error) {
        console.error('❌ Command line verification failed:', error.message)
        console.log('Please manually verify contract address in browser:', implementationAddress)
        console.log('Verification link: https://arbiscan.io/address/' + implementationAddress)
      } else {
        console.log('✅ Command line verification successful!')
        console.log(stdout)
      }
    })
  } catch (error) {
    console.error('❌ Command line verification failed:', error.message)
  }
}

// Recommended pattern for using async/await anywhere
// and properly handling errors
main().catch(error => {
  console.error(error)
  process.exitCode = 1
})
