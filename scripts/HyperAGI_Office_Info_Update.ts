/** @format */

import { ethers, run, upgrades } from 'hardhat'

async function main() {
  console.log('Starting contract upgrade...')

  const _HyperAGI_Office_Info = await ethers.getContractFactory('HyperAGI_Office_Info')
  console.log('Contract factory created successfully')

  const proxyAddress = '0xE8799E8A447fBA9c7185d36FC09aB477B7fe2887' // TODO: 替换为实际的代理地址
  console.log('Proxy contract address:', proxyAddress)

  const HyperAGI_Office_Info = await upgrades.upgradeProxy(proxyAddress, _HyperAGI_Office_Info)
  console.log('Contract upgraded successfully!')
  console.log('Proxy contract address:', await HyperAGI_Office_Info.getAddress())

  const implementationAddress = await upgrades.erc1967.getImplementationAddress(await HyperAGI_Office_Info.getAddress())
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

// We recommend this pattern to be able to use async/await everywhere q
// and properly handle errors.
main().catch(error => {
  console.error(error)
  process.exitCode = 1
})
