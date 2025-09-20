import { ethers } from 'hardhat'

async function main() {
  console.log('Starting deployment of split Agent contracts...')

  // Get deployer account
  const [deployer] = await ethers.getSigners()
  console.log('Deployer address:', deployer.address)

  // 1. Deploy HyperAGI_Agent_Wallet contract
  console.log('\n1. Deploying HyperAGI_Agent_Wallet contract...')
  const AgentWallet = await ethers.getContractFactory('HyperAGI_Agent_Wallet')
  const agentWallet = await AgentWallet.deploy()
  await agentWallet.waitForDeployment()
  const agentWalletAddress = await agentWallet.getAddress()
  console.log('HyperAGI_Agent_Wallet deployment address:', agentWalletAddress)

  // 2. Deploy HyperAGI_Agent contract
  console.log('\n2. Deploying HyperAGI_Agent contract...')
  const Agent = await ethers.getContractFactory('HyperAGI_Agent')
  const agent = await Agent.deploy()
  await agent.waitForDeployment()
  const agentAddress = await agent.getAddress()
  console.log('HyperAGI_Agent deployment address:', agentAddress)

  // 3. Set contract addresses
  console.log('\n3. Setting contract addresses...')

  // Set wallet contract address to main contract
  await agent.setAgentWalletAddress(agentWalletAddress)
  console.log('Wallet contract address set to main contract')

  // 4. Initialize wallet contract
  console.log('\n4. Initializing wallet contract...')
  await agentWallet.initialize(deployer.address)
  console.log('Wallet contract initialization completed')

  // 5. Set default transfer amount
  console.log('\n5. Setting default transfer amount...')
  const defaultAmount = ethers.parseEther('1.0') // 1 ETH
  await agentWallet.setDefaultTransferAmount(defaultAmount)
  console.log('Default transfer amount set to:', ethers.formatEther(defaultAmount), 'ETH')

  console.log('\n✅ Contract deployment completed!')
  console.log('HyperAGI_Agent address:', agentAddress)
  console.log('HyperAGI_Agent_Wallet address:', agentWalletAddress)

  console.log('\n📝 Usage instructions:')
  console.log('1. Creating Agent through agent.mintV3() will automatically generate and allocate wallet address with transfer')
  console.log('2. Get Agent wallet address through agent.getAgentWallet()')
  console.log('3. Check allocated wallet count through agentWallet.getTotalAllocatedWallets()')
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })
