/** @format */

import { ethers, run, upgrades } from 'hardhat'

async function main() {
  const contract = await ethers.getContractFactory('HyperAGI_Agent_Epoch_Payment')
  const instance = await upgrades.deployProxy(contract, [process.env.ADMIN_Wallet_Address])

  await instance.waitForDeployment()

  console.info('contractFactory address:', instance.target)

  await (await instance.setContractAddress(['0xD493BF696b0c98397a87470980f1afCc22CDb289', '0x7B33C8D43C52d0c575eACaEcFdAd68487bfB28Ea', '0x7B33C8D43C52d0c575eACaEcFdAd68487bfB28Ea'])).wait()

  const implementationAddress = await upgrades.erc1967.getImplementationAddress(instance.target)
  await run('verify:verify', {
    address: implementationAddress,
    constructorArguments: [],
  })
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch(error => {
  console.error(error)
  process.exitCode = 1
})
