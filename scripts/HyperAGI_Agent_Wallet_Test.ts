import { ethers } from 'hardhat'

async function main() {
  console.log('Starting HyperAGI_Agent wallet address pool functionality test...')

  // Get deployer account
  const [deployer] = await ethers.getSigners()
  console.log('Deployer address:', deployer.address)

  // Deploy Roles configuration contract
  const RolesCfg = await ethers.getContractFactory('HyperAGI_Roles_Cfg')
  const rolesCfg = await RolesCfg.deploy(deployer.address)
  await rolesCfg.waitForDeployment()
  console.log('Roles configuration contract deployed:', await rolesCfg.getAddress())

  // Deploy Storage contract
  const Storage = await ethers.getContractFactory('HyperAGI_Storage')
  const storage = await Storage.deploy(deployer.address)
  await storage.waitForDeployment()
  console.log('Storage contract deployed:', await storage.getAddress())

  // Deploy Agent contract
  const Agent = await ethers.getContractFactory('HyperAGI_Agent')
  const agent = await Agent.deploy(deployer.address)
  await agent.waitForDeployment()
  console.log('Agent contract deployed:', await agent.getAddress())

  // Set contract addresses
  await agent.setContractAddress([
    await rolesCfg.getAddress(),
    await storage.getAddress(),
    '0x0000000000000000000000000000000000000000', // Temporary address
    '0x0000000000000000000000000000000000000000', // Temporary address
  ])

  // Ensure Storage contract serviceAddress is correctly set
  console.log('Storage contract serviceAddress:', await storage._serviceAddress())

  // Generate some test wallet addresses
  const testWallets = []
  for (let i = 0; i < 5; i++) {
    const wallet = ethers.Wallet.createRandom()
    testWallets.push(wallet.address)
  }

  console.log('Test wallet addresses:', testWallets)

  // Add wallet addresses to address pool
  console.log('Adding wallet addresses to address pool...')
  await agent.addWalletToPool(testWallets)

  // Check wallet address pool status
  const poolInfo = await agent.getWalletPoolInfo()
  console.log('Wallet address pool information:', {
    totalWallets: poolInfo[0].toString(),
    allocatedWallets: poolInfo[1].toString(),
    availableWallets: poolInfo[2].toString(),
  })

  // Set default transfer amount to 0.1 ETH
  console.log('Setting default transfer amount to 0.1 ETH...')
  await agent.setDefaultTransferAmount(ethers.parseEther('0.1'))

  // Send some ETH to contract for transfers
  const tx = await deployer.sendTransaction({
    to: await agent.getAddress(),
    value: ethers.parseEther('1.0'),
  })
  await tx.wait()
  console.log('Sent 1 ETH to contract')

  // Test mintV3 functionality
  console.log('Testing mintV3 functionality...')
  const strParams = ['avatar_url', 'Test Agent', 'This is a test Agent', 'Welcome to use test Agent']

  const mintTx = await agent.mintV3(1, strParams, { value: ethers.parseEther('0.1') })
  const mintReceipt = await mintTx.wait()

  // Find wallet allocation event
  const walletAllocatedEvent = mintReceipt?.logs.find(log => {
    try {
      const parsed = agent.interface.parseLog(log)
      return parsed?.name === 'eveWalletAllocated'
    } catch {
      return false
    }
  })

  if (walletAllocatedEvent) {
    const parsed = agent.interface.parseLog(walletAllocatedEvent)
    console.log('Wallet allocation event:', {
      sid: parsed?.args[0],
      walletAddress: parsed?.args[1],
      transferAmount: ethers.formatEther(parsed?.args[2]),
    })
  }

  // Check allocated wallet address
  const agentSid = '0x' + '1'.padStart(64, '0') // Simplified SID generation
  try {
    const agentWallet = await agent.getAgentWallet(agentSid)
    console.log('Allocated Agent wallet address:', agentWallet)
  } catch (error) {
    console.log('Failed to get Agent wallet address:', error)
  }

  // Check wallet address pool status again
  const poolInfoAfter = await agent.getWalletPoolInfo()
  console.log('Wallet address pool information after mint:', {
    totalWallets: poolInfoAfter[0].toString(),
    allocatedWallets: poolInfoAfter[1].toString(),
    availableWallets: poolInfoAfter[2].toString(),
  })

  console.log('Test completed!')
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })
