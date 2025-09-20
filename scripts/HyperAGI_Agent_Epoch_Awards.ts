/** @format */

import { ethers, run, upgrades } from 'hardhat'

async function main() {
  const contract = await ethers.getContractFactory('HyperAGI_Agent_Epoch_Awards')
  const instance = await upgrades.deployProxy(contract, [process.env.ADMIN_Wallet_Address])
  await instance.waitForDeployment()

  await (await instance.setContractAddress(['0x7B33C8D43C52d0c575eACaEcFdAd68487bfB28Ea', '0x599068C3c2fcfE9b1D04cdCe1B4af3E881f3c2d5', '0xdC775536e0b60dDF0cEAda4Dc0aC8Fd9b9238E2C', '0x6759Aa64749b8fE3E294E7A73Ce6ee14eBF4270d', '0x401f50176C74F0aa49FeF7Aea83eeB349bEABF19'])).wait()

  const HyperAGI_Roles_Cfg = await ethers.getContractAt('HyperAGI_Roles_Cfg', '0x7B33C8D43C52d0c575eACaEcFdAd68487bfB28Ea')

  // await (await HyperAGI_Roles_Cfg.addAdmin(instance.target)).wait()

  // const HyperAGI_AgentWallet = await ethers.getContractAt('HyperAGI_AgentWallet', '0x6759Aa64749b8fE3E294E7A73Ce6ee14eBF4270d')

  // await (await HyperAGI_AgentWallet.grantRole('0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6', instance.target)).wait()

  console.info('contractFactory address:', instance.target)

  const implementationAddress = await upgrades.erc1967.getImplementationAddress(await instance.getAddress())

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
