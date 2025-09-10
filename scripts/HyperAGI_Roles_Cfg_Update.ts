/** @format */

import { ethers, run, upgrades } from 'hardhat'

async function main() {
  const _HyperAGI_Roles_Cfg = await ethers.getContractFactory('HyperAGI_Roles_Cfg')

  const proxyAddress = '0x7B33C8D43C52d0c575eACaEcFdAd68487bfB28Ea' // Your proxy contract address

  const proxyContract = await ethers.getContractAt('HyperAGI_Roles_Cfg', proxyAddress)

  const owner = await proxyContract.owner()

  console.log('Proxy Owner:', owner)

  const accounts = await ethers.getSigners()

  const onlyOwner = accounts[0].address

  console.log('onlyOwner:', onlyOwner)

  const instance = await upgrades.upgradeProxy('0x7B33C8D43C52d0c575eACaEcFdAd68487bfB28Ea', _HyperAGI_Roles_Cfg)

  const implementationAddress = await upgrades.erc1967.getImplementationAddress(instance.target)
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
