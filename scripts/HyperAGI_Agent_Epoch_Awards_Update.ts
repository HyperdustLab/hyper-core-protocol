/** @format */

import { ethers, run, upgrades } from 'hardhat'

async function main() {
  const _HyperAGI_Agent_Epoch_Awards = await ethers.getContractFactory('HyperAGI_Agent_Epoch_Awards')

  const HyperAGI_Agent_Epoch_Awards = await upgrades.upgradeProxy('0x6096547Ec0eDF8EBE4b2eB461018B20b1201771d', _HyperAGI_Agent_Epoch_Awards)

  const implementationAddress = await upgrades.erc1967.getImplementationAddress(await HyperAGI_Agent_Epoch_Awards.getAddress())
  console.log('Implementation contract address:', implementationAddress)

  // Wait a bit for the transaction to be indexed
  console.log('⏳ Waiting for block explorer to index the contract...')
  await new Promise(resolve => setTimeout(resolve, 10000))

  // Method 1: Try verification with standard JSON input
  try {
    console.log('📝 Attempting verification with standard JSON input...')
    await run('verify:verify', {
      address: implementationAddress,
      constructorArguments: [],
    })
    console.log('✅ Verification successful!')
    return
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error)
    console.log('⚠️  First verification attempt result:', errorMessage)

    // If already verified, we need to force re-verification
    if (errorMessage.includes('already verified')) {
      console.log('⚠️  Contract appears to be already verified, but may not be correct')
      console.log('🔄 Attempting force verification...')
    }
  }

  // Method 2: Force verification to overwrite any existing verification
  try {
    console.log('🔄 Force verifying with correct compiler settings...')
    await run('verify:verify', {
      address: implementationAddress,
      constructorArguments: [],
      force: true,
    })
    console.log('✅ Force verification successful!')
    return
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error)
    console.error('❌ Force verification error:', errorMessage)
  }

  // Method 3: Provide manual instructions
  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
  console.log('📋 Manual Verification Instructions:')
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n')
  console.log('Contract Address:', implementationAddress)
  console.log('Verification URL:', `https://explorer.hyperagi.network/address/${implementationAddress}#code`)
  console.log('\n🔧 Compiler Settings:')
  console.log('  - Compiler Version: 0.8.20')
  console.log('  - Optimization: Enabled')
  console.log('  - Runs: 2000')
  console.log('  - Via IR: true')
  console.log('\n💡 Alternative: Use Standard JSON Input from artifacts/build-info/')
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n')
}

// We recommend this pattern to be able to use async/await everywhere q
// and properly handle errors.
main().catch(error => {
  console.error(error)
  process.exitCode = 1
})
