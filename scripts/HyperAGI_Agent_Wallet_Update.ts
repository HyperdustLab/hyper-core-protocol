/** @format */

import { ethers, run, upgrades } from 'hardhat'

async function main() {
  console.log('Starting HyperAGI_AgentWallet contract upgrade...')

  const _HyperAGI_Agent_Wallet = await ethers.getContractFactory('HyperAGI_AgentWallet')
  console.log('Contract factory created successfully')

  const proxyAddress = '0x6759Aa64749b8fE3E294E7A73Ce6ee14eBF4270d'
  console.log('Proxy contract address:', proxyAddress)

  const HyperAGI_Agent_Wallet = await upgrades.upgradeProxy(proxyAddress, _HyperAGI_Agent_Wallet)
  console.log('Contract upgraded successfully!')
  console.log('Proxy contract address:', await HyperAGI_Agent_Wallet.getAddress())

  const implementationAddress = await upgrades.erc1967.getImplementationAddress(await HyperAGI_Agent_Wallet.getAddress())
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
        console.log('Block explorer URL: https://explorer.hyperagi.network/address/' + implementationAddress)
      }
    }
  }

  console.log('\n✅ HyperAGI_Agent_Wallet contract upgrade completed!')
  console.log('Proxy address:', await HyperAGI_Agent_Wallet.getAddress())
  console.log('Implementation address:', implementationAddress)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch(error => {
  console.error(error)
  process.exitCode = 1
})
