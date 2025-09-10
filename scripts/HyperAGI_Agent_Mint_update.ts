/** @format */

import { ethers, run, upgrades } from 'hardhat'

async function main() {
  const _HyperAGI_Agent_Mint = await ethers.getContractFactory('HyperAGI_Agent_Mint')

  const HyperAGI_Agent_Mint = await upgrades.upgradeProxy('0x7846E507378B94aE8FF28D454b563E35a4D1d81d', _HyperAGI_Agent_Mint)

  // Verify implementation contract
  const implementationAddress = await upgrades.erc1967.getImplementationAddress(HyperAGI_Agent_Mint.target as string)

  console.log('Implementation address:', implementationAddress)

  try {
    await run('verify:verify', {
      address: implementationAddress,
      constructorArguments: [],
    })
    console.log('Contract verified successfully')
  } catch (error) {
    console.error('Verification failed:', error)
  }
}

// We recommend this pattern to be able to use async/await everywhere q
// and properly handle errors.
main().catch(error => {
  console.error(error)
  process.exitCode = 1
})
