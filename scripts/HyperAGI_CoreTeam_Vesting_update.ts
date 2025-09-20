/** @format */

import { ethers, run, upgrades } from 'hardhat'

async function main() {
  console.log('Starting contract upgrade...')

  const _HyperAGI_CoreTeam_Vesting = await ethers.getContractFactory('HyperAGI_CoreTeam_Vesting')
  console.log('Contract factory created successfully')

  const proxyAddress = '0xc43FEe967318D92eFdf797C0dAEb5736E1E17F84'
  console.log('Proxy contract address:', proxyAddress)

  const instance = await upgrades.upgradeProxy(proxyAddress, _HyperAGI_CoreTeam_Vesting)
  console.log('Contract upgrade successful!')
  console.log('Proxy contract address:', await instance.getAddress())

  // Get implementation contract address
  const implementationAddress = await upgrades.erc1967.getImplementationAddress(await instance.getAddress())
  console.log('Implementation contract address:', implementationAddress)

  // Wait for block confirmation
  console.log('Waiting for block confirmation...')
  await new Promise(resolve => setTimeout(resolve, 10000))

  console.log('Starting contract source code verification...')

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
    const command = `npx hardhat verify --network hyperAGI --force ${implementationAddress}`
    console.log('Executing command:', command)

    exec(command, (error, stdout, stderr) => {
      if (error) {
        console.error('❌ Command line verification failed:', error.message)
        console.log('Please manually verify contract address in browser:', implementationAddress)
        console.log('Verification link: https://explorer.hyperagi.network/address/' + implementationAddress)
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

// We recommend this pattern to be able to use async/await everywhere q
// and properly handle errors.
main().catch(error => {
  console.error(error)
  process.exitCode = 1
})
