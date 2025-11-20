/** @format */

import { ethers, run, upgrades } from 'hardhat'

async function main() {
  console.log('Starting contract upgrade...')

  const _HyperAGI_Employee_Contract = await ethers.getContractFactory('HyperAGI_Employee_Contract')
  console.log('Contract factory created successfully')

  const proxyAddress = '0x88f89323d03618181744d0e9f99969B73b91d3e6' // TODO: 替换为实际的代理地址
  console.log('Proxy contract address:', proxyAddress)

  const HyperAGI_Employee_Contract = await upgrades.upgradeProxy(proxyAddress, _HyperAGI_Employee_Contract)
  console.log('Contract upgraded successfully!')
  console.log('Proxy contract address:', await HyperAGI_Employee_Contract.getAddress())

  const implementationAddress = await upgrades.erc1967.getImplementationAddress(await HyperAGI_Employee_Contract.getAddress())
  console.log('Implementation contract address:', implementationAddress)

  // Wait for a few block confirmations
  console.log('Waiting for block confirmations...')
  await new Promise(resolve => setTimeout(resolve, 10000))

  console.log('Starting contract source code verification...')
  try {
    await run('verify:verify', {
      address: implementationAddress,
      constructorArguments: [],
    })
    console.log('✅ Contract verification successful!')
  } catch (error) {
    console.error('❌ Verification failed:', error)

    // Check if the error is about contract already being verified
    if (error instanceof Error && error.message && error.message.includes('already verified')) {
      console.log('ℹ️ Contract is already verified on the block explorer')
      console.log('ℹ️ No further action needed')
    } else {
      console.log('Trying with force verification...')
      try {
        await run('verify:verify', {
          address: implementationAddress,
          constructorArguments: [],
          force: true,
        })
        console.log('✅ Contract verification successful with force!')
      } catch (forceError) {
        console.error('❌ Force verification also failed:', forceError)
        console.log('Please manually verify contract address:', implementationAddress)
      }
    }
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch(error => {
  console.error(error)
  process.exitCode = 1
})
