/** @format */

import { ethers } from 'hardhat'

async function main() {
  console.log('🔍 Debugging setCounts function call...')

  const contractAddress = '0x7d2524F684A743a0115Eb0bdAe11Cad7ceA8012E'
  const callerAddress = '0xaaC73e223DEc87218d849992b73B52be81910cAc'

  console.log('Contract address:', contractAddress)
  console.log('Caller address:', callerAddress)

  try {
    // Get contract instance
    const HyperAGI_Agent = await ethers.getContractAt('HyperAGI_Agent', contractAddress)
    console.log('✅ Contract instance created')

    // Check contract owner
    const owner = await HyperAGI_Agent.owner()
    console.log('Contract owner:', owner)
    console.log('Is caller the owner?', callerAddress.toLowerCase() === owner.toLowerCase())

    // Check roles config address
    const rolesCfgAddress = await HyperAGI_Agent._rolesCfgAddress()
    console.log('Roles config address:', rolesCfgAddress)

    // Check storage address
    const storageAddress = await HyperAGI_Agent._storageAddress()
    console.log('Storage address:', storageAddress)

    // Check if roles config is set
    if (rolesCfgAddress !== '0x0000000000000000000000000000000000000000') {
      try {
        const rolesCfg = await ethers.getContractAt('HyperAGI_Roles_Cfg', rolesCfgAddress)
        const hasAdminRole = await rolesCfg.hasAdminRole(callerAddress)
        console.log('Has admin role:', hasAdminRole)
      } catch (error) {
        console.log('❌ Error checking admin role:', error instanceof Error ? error.message : error)
      }
    } else {
      console.log('⚠️ Roles config address not set')
    }

    // Check current counts
    try {
      const totalCount = await HyperAGI_Agent.getTotalCount()
      const onlineCount = await HyperAGI_Agent.getOnlineCount()
      console.log('Current total count:', totalCount.toString())
      console.log('Current online count:', onlineCount.toString())
    } catch (error) {
      console.log('❌ Error getting current counts:', error instanceof Error ? error.message : error)
    }

    // Try to call setCounts with proper error handling
    console.log('\n🧪 Testing setCounts function...')
    try {
      // First check if we can estimate gas
      const gasEstimate = await HyperAGI_Agent.setCounts.estimateGas(1000, 1)
      console.log('Gas estimate:', gasEstimate.toString())

      // Try to call the function (this will fail if no permission)
      const tx = await HyperAGI_Agent.setCounts(1000, 1)
      console.log('✅ Transaction sent:', tx.hash)

      const receipt = await tx.wait()
      console.log('✅ Transaction confirmed:', receipt?.hash)
    } catch (error) {
      console.log('❌ setCounts call failed:', error instanceof Error ? error.message : error)

      // Check if it's a permission error
      if (error instanceof Error && error.message.includes('not admin role')) {
        console.log('🔑 Permission denied: Caller does not have admin role')
        console.log('💡 Solutions:')
        console.log('   1. Use the contract owner account')
        console.log('   2. Grant admin role to the caller address')
        console.log('   3. Use setCountsInternal function instead')
      } else if (error instanceof Error && error.message.includes('roles config not set')) {
        console.log('⚙️ Configuration error: Roles config address not set')
        console.log('💡 Solution: Set the roles config address first')
      }
    }
  } catch (error) {
    console.error('❌ Debug failed:', error instanceof Error ? error.message : error)
  }
}

main().catch(error => {
  console.error(error)
  process.exitCode = 1
})
