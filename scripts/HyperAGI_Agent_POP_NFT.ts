/** @format */

import { ethers, run } from 'hardhat'

async function main() {
  const abiCoder = new ethers.AbiCoder()

  const contract = await ethers.deployContract('HyperAGI_721', ['HyperAGI Agent POP NFT', 'HAPN', process.env.ADMIN_Wallet_Address])
  await contract.waitForDeployment()

  console.info('contractFactory address:', contract.target)

  const initializeData = abiCoder.encode(
    ['string', 'string', 'address'], // Initialize function parameter types
    ['HyperAGI Agent POP NFT', 'HAPN', process.env.ADMIN_Wallet_Address] // Initialize function parameter values
  )

  console.info('initializeData:', initializeData)
}

// We recommend this pattern to be able to use async/await everywhere q
// and properly handle errors.
main().catch(error => {
  console.error(error)
  process.exitCode = 1
})
