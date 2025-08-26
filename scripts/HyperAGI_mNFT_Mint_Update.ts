/** @format */

import { ethers, run, upgrades } from 'hardhat'

async function main() {
  const _HyperAGI_mNFT_Mint = await ethers.getContractFactory('HyperAGI_mNFT_Mint')

  const HyperAGI_mNFT_Mint = await upgrades.upgradeProxy('0xE2B95DA97db210b51096ACbe56804E7A2604aB9D', _HyperAGI_mNFT_Mint)

  const implementationAddress = await upgrades.erc1967.getImplementationAddress(HyperAGI_mNFT_Mint.target)
  await run('verify:verify', {
    address: implementationAddress,
    constructorArguments: [],
  })
}

// We recommend this pattern to be able to use async/await everywhere q
// and properly handle errors.
main().catch(error => {
  console.error(error)
  process.exitCode = 1
})
