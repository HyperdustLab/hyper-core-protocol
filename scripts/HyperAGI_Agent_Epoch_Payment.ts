/** @format */

import { ethers, run, upgrades } from 'hardhat'

async function main() {
  const contract = await ethers.getContractFactory('HyperAGI_Agent_Epoch_Payment')
  const instance = await upgrades.deployProxy(contract, [process.env.ADMIN_Wallet_Address])

  await instance.waitForDeployment()

  console.info('contractFactory address:', instance.target)

  await (await instance.setContractAddress([process.env.ROLES_CFG_ADDRESS, '0x4C3D5B8c8b065B97Ec5b7e0f8dFA2299CC5Ed82a'])).wait()

  const implementationAddress = await upgrades.erc1967.getImplementationAddress(await instance.getAddress())
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
