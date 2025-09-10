/** @format */

import { ethers, run, upgrades } from 'hardhat'

require('dotenv').config()

async function main() {
  console.log('Starting deployment of HyperAGI_Agent_Wallet contract...')

  // Check required environment variables
  if (!process.env.ADMIN_Wallet_Address) {
    throw new Error('ADMIN_Wallet_Address environment variable not set')
  }
  if (!process.env.ROLES_CFG_ADDRESS) {
    throw new Error('ROLES_CFG_ADDRESS environment variable not set')
  }

  console.log('Admin address:', process.env.ADMIN_Wallet_Address)
  console.log('Roles config address:', process.env.ROLES_CFG_ADDRESS)

  // Deploy HyperAGI_Agent_Wallet contract
  const contract = await ethers.getContractFactory('HyperAGI_Agent_Wallet')
  console.log('Contract factory obtained successfully')

  const instance = await upgrades.deployProxy(contract, [process.env.ADMIN_Wallet_Address])
  console.log('Proxy contract deployed successfully')

  await instance.waitForDeployment()
  console.log('Waiting for deployment to complete')

  const contractAddress = await instance.getAddress()
  console.log('HyperAGI_Agent_Wallet contract address:', contractAddress)

  // Set roles config address
  await (await instance.setRolesCfgAddress(process.env.ROLES_CFG_ADDRESS)).wait()
  console.log('Roles config address set successfully')

  // Set default transfer amount to 1 ETH
  await (await instance.setDefaultTransferAmount(ethers.parseEther('1'))).wait()
  console.log('Default transfer amount set successfully: 1 ETH')

  // Verify contract
  const implementationAddress = await upgrades.erc1967.getImplementationAddress(contractAddress)
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

  console.log('\n✅ HyperAGI_Agent_Wallet contract deployment completed!')
  console.log('Contract address:', contractAddress)
  console.log('Implementation address:', implementationAddress)

  console.log('\n📝 Usage instructions:')
  console.log('1. Use allocateWalletForAgent() to allocate wallet and transfer funds for Agent')
  console.log('2. Use getAgentWallet() to get Agent wallet address')
  console.log('3. Use getTotalAllocatedWallets() to view the number of allocated wallets')
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch(error => {
  console.error(error)
  process.exitCode = 1
})
