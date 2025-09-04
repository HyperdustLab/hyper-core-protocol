/** @format */

import { ethers, run, upgrades } from 'hardhat'

async function main() {
  // const _HyperAGI_Payment_Wallet = await ethers.getContractFactory('HyperAGI_Payment_Wallet')
  // await upgrades.upgradeProxy('0x5f1EcEC2891B81Fd57FE134656E907C1B58bD3f2', _HyperAGI_Payment_Wallet)
}

// We recommend this pattern to be able to use async/await everywhere q
// and properly handle errors.
main().catch(error => {
  console.error(error)
  process.exitCode = 1
})
