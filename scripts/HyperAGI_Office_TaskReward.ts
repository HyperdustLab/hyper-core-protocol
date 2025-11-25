/** @format */

import { ethers, run, upgrades } from 'hardhat'

async function main() {
  const _HyperAGI_Storage = await ethers.getContractFactory('HyperAGI_Storage')
  const HyperAGI_Storage = await upgrades.deployProxy(_HyperAGI_Storage, [process.env.ADMIN_Wallet_Address])
  await HyperAGI_Storage.waitForDeployment()

  console.info('HyperAGI_Storage:', HyperAGI_Storage.target)

  const contract = await ethers.getContractFactory('HyperAGI_Office_TaskReward')
  const instance = await upgrades.deployProxy(contract, [process.env.ADMIN_Wallet_Address])

  await instance.waitForDeployment()

  await (await HyperAGI_Storage.setServiceAddress(String(instance.target))).wait()

  await (await instance.setContractAddress([String(HyperAGI_Storage.target), process.env.ROLES_CFG_ADDRESS, '0x7f5Ca488c623d4DA355fb1307c41809EE3dC7ADD', '0x574F5d09F48092C4528705fb69A702C153773369', '0xb90F1d2b0eF4aC49548cad06d44Bc1145793332C'])).wait()

  console.info('contractFactory address:', instance.target)

  const implementationAddress = await upgrades.erc1967.getImplementationAddress(String(instance.target))
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
