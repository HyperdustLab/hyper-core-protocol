/** @format */

import { ethers, run, upgrades } from 'hardhat'

async function main() {
  console.log('Starting verification of upgraded contract...')

  const proxyAddress = '0xD493BF696b0c98397a87470980f1afCc22CDb289'
  console.log('Proxy contract address:', proxyAddress)

  // Get proxy contract instance
  const _HyperAGI_Agent = await ethers.getContractFactory('HyperAGI_Agent')
  const proxyContract = _HyperAGI_Agent.attach(proxyAddress)

  console.log('Proxy contract address:', await proxyContract.getAddress())

  // Get implementation contract address
  const implementationAddress = await upgrades.erc1967.getImplementationAddress(await proxyContract.getAddress())
  console.log('Implementation contract address:', implementationAddress)

  // Wait for several block confirmations
  console.log('Waiting for block confirmations...')
  await new Promise(resolve => setTimeout(resolve, 5000))

  console.log('Starting contract source code verification...')

  // Method 1: Use --force flag for forced verification
  try {
    console.log('Trying forced verification...')
    await run('verify:verify', {
      address: implementationAddress,
      constructorArguments: [],
      force: true,
    })
    console.log('✅ Forced verification successful!')
    return
  } catch (error) {
    console.error('❌ Forced verification failed:', error.message)
  }

  // Method 2: Without forced verification
  try {
    console.log('Trying normal verification...')
    await run('verify:verify', {
      address: implementationAddress,
      constructorArguments: [],
    })
    console.log('✅ Normal verification successful!')
    return
  } catch (error) {
    console.error('❌ Normal verification failed:', error.message)
  }

  // Method 3: Use command line approach
  console.log('Trying command line verification...')
  try {
    const { exec } = require('child_process')
    const command = `npx hardhat verify --network hyperAGI --force ${implementationAddress}`
    console.log('Executing command:', command)

    exec(command, (error, stdout, stderr) => {
      if (error) {
        console.error('❌ Command line verification failed:', error.message)
        console.log('Please manually verify contract address in browser:', implementationAddress)
        console.log('Verification URL: https://explorer.hyperagi.network/address/' + implementationAddress)
      } else {
        console.log('✅ Command line verification successful!')
        console.log(stdout)
      }
    })
  } catch (error) {
    console.error('❌ Command line verification failed:', error.message)
  }

  console.log('\n=== Verification Information ===')
  console.log('Proxy contract address:', proxyAddress)
  console.log('Implementation contract address:', implementationAddress)
  console.log('Browser link: https://explorer.hyperagi.network/address/' + implementationAddress)
  console.log('If automatic verification fails, please manually verify the above address in browser')
}

main().catch(error => {
  console.error('Script execution failed:', error)
  process.exitCode = 1
})
