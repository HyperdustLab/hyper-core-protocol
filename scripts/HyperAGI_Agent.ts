/** @format */

import { ethers, run, upgrades } from 'hardhat'

async function main() {
  const _HyperAGI_Storage = await ethers.getContractFactory('HyperAGI_Storage')
  const HyperAGI_Storage = await upgrades.deployProxy(_HyperAGI_Storage, [process.env.ADMIN_Wallet_Address])
  await HyperAGI_Storage.waitForDeployment()

  console.info('HyperAGI_Storage:', HyperAGI_Storage.target)

  const contract = await ethers.getContractFactory('HyperAGI_Agent')

  console.info('getContractFactory')

  const instance = await upgrades.deployProxy(contract, [process.env.ADMIN_Wallet_Address])

  console.info('deployProxy')

  await instance.waitForDeployment()

  console.info('waitForDeployment')

  await (await HyperAGI_Storage.setServiceAddress(instance.target)).wait()

  console.info('setServiceAddress')

  await (await instance.setContractAddress([process.env.ROLES_CFG_ADDRESS, HyperAGI_Storage.target, '0x709722ed57452a5B25860e4C8D1F7BB5275ac00B', '0x615f77318Ff5C101ff513e673c937C71ffDed5B3', '0x77f50749a65aad04EE0A63f96466E39912EF2A8b'])).wait()

  console.info('contractFactory address:', instance.target)

  await (await instance.setGroundRodLevels([1730870914364], [5])).wait()

  const HyperAGI_Roles_Cfg = await ethers.getContractAt('HyperAGI_Roles_Cfg', process.env.ROLES_CFG_ADDRESS)

  await (await HyperAGI_Roles_Cfg.addAdmin(instance.target)).wait()

  const implementationAddress = await upgrades.erc1967.getImplementationAddress(instance.target)

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
}

// We recommend this pattern to be able to use async/await everywhere q
// and properly handle errors.
main().catch(error => {
  console.error(error)
  process.exitCode = 1
})
