import { ethers } from 'hardhat'

async function main() {
  console.log('Starting HyperAGI_Agent contract deployment...')

  // Get deployer account
  const [deployer] = await ethers.getSigners()
  console.log('Deployer address:', deployer.address)

  // Deploy Roles configuration contract
  console.log('Deploying Roles configuration contract...')
  const RolesCfg = await ethers.getContractFactory('HyperAGI_Roles_Cfg')
  const rolesCfg = await RolesCfg.deploy(deployer.address)
  await rolesCfg.waitForDeployment()
  console.log('Roles configuration contract deployed:', await rolesCfg.getAddress())

  // Deploy Storage contract
  console.log('Deploying Storage contract...')
  const Storage = await ethers.getContractFactory('HyperAGI_Storage')
  const storage = await Storage.deploy(deployer.address)
  await storage.waitForDeployment()
  console.log('Storage contract deployed:', await storage.getAddress())

  // Deploy Agent contract
  console.log('Deploying Agent contract...')
  const Agent = await ethers.getContractFactory('HyperAGI_Agent')
  const agent = await Agent.deploy(deployer.address)
  await agent.waitForDeployment()
  console.log('Agent contract deployed:', await agent.getAddress())

  // Set contract addresses
  console.log('Setting contract addresses...')
  await agent.setContractAddress([
    await rolesCfg.getAddress(),
    await storage.getAddress(),
    '0x0000000000000000000000000000000000000000', // Temporary address
    '0x0000000000000000000000000000000000000000', // Temporary address
  ])

  // Verify Storage contract serviceAddress setting
  const serviceAddress = await storage._serviceAddress()
  console.log('Storage contract serviceAddress:', serviceAddress)
  console.log('Agent contract address:', await agent.getAddress())
  console.log('serviceAddress set correctly:', serviceAddress === (await agent.getAddress()))

  // Deploy wallet contract
  console.log('Deploying wallet contract...')
  const AgentWallet = await ethers.getContractFactory('HyperAGI_Agent_Wallet')
  const agentWallet = await AgentWallet.deploy()
  await agentWallet.waitForDeployment()
  console.log('Wallet contract deployed:', await agentWallet.getAddress())

  // Set wallet contract address to main contract
  console.log('Setting wallet contract address to main contract...')
  await agent.setAgentWalletAddress(await agentWallet.getAddress())

  // Initialize wallet contract
  console.log('Initializing wallet contract...')
  await agentWallet.initialize(deployer.address)

  // Set default transfer amount
  console.log('Setting default transfer amount to 0.01 ETH...')
  await agentWallet.setDefaultTransferAmount(ethers.parseEther('0.01'))

  // Send ETH to contract
  console.log('Sending 0.1 ETH to contract...')
  const tx = await deployer.sendTransaction({
    to: await agent.getAddress(),
    value: ethers.parseEther('0.1'),
  })
  await tx.wait()
  console.log('ETH sent successfully')

  // Check contract balance
  const contractBalance = await ethers.provider.getBalance(await agent.getAddress())
  console.log('Contract balance:', ethers.formatEther(contractBalance), 'ETH')

  console.log('Deployment completed!')
  console.log('Contract addresses:')
  console.log('- Roles configuration:', await rolesCfg.getAddress())
  console.log('- Storage:', await storage.getAddress())
  console.log('- Agent:', await agent.getAddress())
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })
