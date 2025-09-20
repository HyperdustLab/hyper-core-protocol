/** @format */

import { ethers, run, upgrades } from 'hardhat'

async function main() {
  const _HyperAGI_Agent_Epoch_Awards = await ethers.getContractFactory('HyperAGI_Agent_Epoch_Awards')

  const HyperAGI_Agent_Epoch_Awards = await upgrades.upgradeProxy('0x16C0E2aDF22f4A4613f408CdEed62Bc46B13Aa4E', _HyperAGI_Agent_Epoch_Awards)

  const implementationAddress = await upgrades.erc1967.getImplementationAddress(await HyperAGI_Agent_Epoch_Awards.getAddress())
  console.log('Implementation contract address:', implementationAddress)

  // Method 1: Normal verification first
  try {
    console.log('Attempting normal verification...')
    await run('verify:verify', {
      address: implementationAddress,
      constructorArguments: [],
    })
    console.log('✅ Normal verification successful!')
    return
  } catch (error) {
    console.error('❌ Normal verification failed:', error instanceof Error ? error.message : error)

    // Check if the error is about contract already being verified
    if (error instanceof Error && error.message && error.message.includes('already verified')) {
      console.log('ℹ️ Contract is already verified on the block explorer')
      console.log('ℹ️ No further action needed')
      return
    }
  }

  // Method 2: Force verification
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
    console.error('❌ Force verification failed:', error instanceof Error ? error.message : error)
  }

  // Method 3: Command line verification
  console.log('Attempting command line verification...')
  try {
    const { exec } = require('child_process')
    const command = `npx hardhat verify --network hyperAGI --force ${implementationAddress}`
    console.log('Executing command:', command)

    exec(command, (error: any, stdout: any, stderr: any) => {
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
    console.error('❌ Command line verification failed:', error instanceof Error ? error.message : error)
  }
}

// We recommend this pattern to be able to use async/await everywhere q
// and properly handle errors.
main().catch(error => {
  console.error(error)
  process.exitCode = 1
})
