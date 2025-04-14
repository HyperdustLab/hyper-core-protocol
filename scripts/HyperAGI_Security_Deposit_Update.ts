/** @format */

import { ethers, run, upgrades } from 'hardhat'

async function main() {
  const _HyperAGI_Security_Deposit = await ethers.getContractFactory('HyperAGI_Security_Deposit')

  const HyperAGI_Security_Deposit = await upgrades.upgradeProxy('0x78648b6a5d4b136E30935B5A22B93625AEb58c51', _HyperAGI_Security_Deposit)

  const implementationAddress = await upgrades.erc1967.getImplementationAddress(HyperAGI_Security_Deposit.target)
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
