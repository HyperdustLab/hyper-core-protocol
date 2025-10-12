/** @format */

import { exec } from 'child_process'
import { promisify } from 'util'

const execAsync = promisify(exec)

/**
 * Force Verify Contract Script
 * Force re-verification using command line, even if the contract is already verified
 *
 * Usage:
 * npx hardhat run scripts/force_verify.ts --network hyperAGI
 */

async function main() {
  const implementationAddress = '0x27e5feeA92166AF33772bdf87B9e274df54FBE18'
  const contractPath = 'contracts/epoch/HyperAGI_Agent_Epoch_Awards.sol:HyperAGI_Agent_Epoch_Awards'

  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
  console.log('🔥 Force Verify Contract Source Code')
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n')
  console.log('📍 Implementation Contract Address:', implementationAddress)
  console.log('📝 Contract Path:', contractPath)
  console.log('🌐 Network: hyperAGI')
  console.log('')

  try {
    console.log('⏳ Executing force verification command...\n')

    const command = `npx hardhat verify --network hyperAGI --contract "${contractPath}" --force ${implementationAddress}`
    console.log('🔧 Executing command:', command)
    console.log('')

    const { stdout, stderr } = await execAsync(command, {
      maxBuffer: 1024 * 1024 * 10, // 10MB buffer
    })

    if (stdout) {
      console.log(stdout)
    }

    if (stderr && !stderr.includes('WARNING')) {
      console.error('⚠️  Error output:', stderr)
    }

    console.log('\n✅ Verification command completed!')
    console.log(`🔗 View results: https://explorer.hyperagi.network/address/${implementationAddress}#code`)
  } catch (error: any) {
    console.error('\n❌ Error during verification:\n')

    if (error.stdout) {
      console.log(error.stdout)
    }

    if (error.stderr) {
      console.error(error.stderr)
    }

    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
    console.log('🛠️  Troubleshooting Suggestions')
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n')
    console.log('1. Confirm the contract has been successfully deployed to the chain')
    console.log('2. Confirm network configuration is correct (hardhat.config.ts)')
    console.log('3. Try cleaning cache and recompiling:')
    console.log('   npx hardhat clean')
    console.log('   npx hardhat compile')
    console.log('4. Use standard JSON input for manual verification')
    console.log('')

    throw error
  }
}

main().catch(error => {
  console.error('\n💥 Script execution failed')
  process.exitCode = 1
})
