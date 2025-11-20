/** @format */

import { ethers, run, upgrades } from 'hardhat'

async function main() {
  console.log('Starting HyperAGI_Agent_Epoch_Payment contract upgrade...')

  const _HyperAGI_Agent_Epoch_Payment = await ethers.getContractFactory('HyperAGI_Agent_Epoch_Payment')
  console.log('Contract factory created successfully')

  // TODO: Please replace with actual proxy contract address
  const proxyAddress = '0x6096547Ec0eDF8EBE4b2eB461018B20b1201771d' // Need to replace with actual address
  console.log('Proxy contract address:', proxyAddress)

  const HyperAGI_Agent_Epoch_Payment = await upgrades.upgradeProxy(proxyAddress, _HyperAGI_Agent_Epoch_Payment)
  console.log('Contract upgrade successful!')
  console.log('Proxy contract address:', await HyperAGI_Agent_Epoch_Payment.getAddress())

  const implementationAddress = await upgrades.erc1967.getImplementationAddress(await HyperAGI_Agent_Epoch_Payment.getAddress())
  console.log('Implementation contract address:', implementationAddress)

  // Wait for several block confirmations
  console.log('Waiting for block confirmations...')
  await new Promise(resolve => setTimeout(resolve, 10000))

  console.log('Starting contract source code verification...')
  try {
    await run('verify:verify', {
      address: implementationAddress,
      constructorArguments: [],
      force: true, // Force verification even if contract is partially verified
    })
    console.log('✅ Contract verification successful!')
  } catch (error) {
    console.error('❌ Force verification failed:', error)
    console.log('Trying without force verification...')

    try {
      await run('verify:verify', {
        address: implementationAddress,
        constructorArguments: [],
      })
      console.log('✅ Contract verification successful!')
    } catch (secondError) {
      console.error('❌ Verification failed:', secondError)
      console.log('Please manually verify contract address:', implementationAddress)
    }
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch(error => {
  console.error(error)
  process.exitCode = 1
})
