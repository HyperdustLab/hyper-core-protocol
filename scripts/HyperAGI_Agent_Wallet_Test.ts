import { ethers } from "hardhat";

async function main() {
  console.log("开始测试HyperAGI_Agent钱包地址库功能...");

  // 获取部署者账户
  const [deployer] = await ethers.getSigners();
  console.log("部署者地址:", deployer.address);

  // 部署Roles配置合约
  const RolesCfg = await ethers.getContractFactory("HyperAGI_Roles_Cfg");
  const rolesCfg = await RolesCfg.deploy(deployer.address);
  await rolesCfg.waitForDeployment();
  console.log("Roles配置合约已部署:", await rolesCfg.getAddress());

  // 部署Storage合约
  const Storage = await ethers.getContractFactory("HyperAGI_Storage");
  const storage = await Storage.deploy(deployer.address);
  await storage.waitForDeployment();
  console.log("Storage合约已部署:", await storage.getAddress());

  // 部署Agent合约
  const Agent = await ethers.getContractFactory("HyperAGI_Agent");
  const agent = await Agent.deploy(deployer.address);
  await agent.waitForDeployment();
  console.log("Agent合约已部署:", await agent.getAddress());

  // 设置合约地址
  await agent.setContractAddress([
    await rolesCfg.getAddress(),
    await storage.getAddress(),
    "0x0000000000000000000000000000000000000000", // 临时地址
    "0x0000000000000000000000000000000000000000"  // 临时地址
  ]);

  // 确保Storage合约的serviceAddress已正确设置
  console.log("Storage合约serviceAddress:", await storage._serviceAddress());

  // 生成一些测试钱包地址
  const testWallets = [];
  for (let i = 0; i < 5; i++) {
    const wallet = ethers.Wallet.createRandom();
    testWallets.push(wallet.address);
  }

  console.log("测试钱包地址:", testWallets);

  // 添加钱包地址到地址库
  console.log("添加钱包地址到地址库...");
  await agent.addWalletToPool(testWallets);

  // 检查钱包地址库状态
  const poolInfo = await agent.getWalletPoolInfo();
  console.log("钱包地址库信息:", {
    totalWallets: poolInfo[0].toString(),
    allocatedWallets: poolInfo[1].toString(),
    availableWallets: poolInfo[2].toString()
  });

  // 设置默认转账金额为0.1 ETH
  console.log("设置默认转账金额为0.1 ETH...");
  await agent.setDefaultTransferAmount(ethers.parseEther("0.1"));

  // 向合约发送一些ETH用于转账
  const tx = await deployer.sendTransaction({
    to: await agent.getAddress(),
    value: ethers.parseEther("1.0")
  });
  await tx.wait();
  console.log("已向合约发送1 ETH");

  // 测试mintV3功能
  console.log("测试mintV3功能...");
  const strParams = [
    "avatar_url",
    "测试Agent",
    "这是一个测试Agent",
    "欢迎使用测试Agent"
  ];

  const mintTx = await agent.mintV3(1, strParams, { value: ethers.parseEther("0.1") });
  const mintReceipt = await mintTx.wait();

  // 查找钱包分配事件
  const walletAllocatedEvent = mintReceipt?.logs.find(log => {
    try {
      const parsed = agent.interface.parseLog(log);
      return parsed?.name === "eveWalletAllocated";
    } catch {
      return false;
    }
  });

  if (walletAllocatedEvent) {
    const parsed = agent.interface.parseLog(walletAllocatedEvent);
    console.log("钱包分配事件:", {
      sid: parsed?.args[0],
      walletAddress: parsed?.args[1],
      transferAmount: ethers.formatEther(parsed?.args[2])
    });
  }

  // 检查分配的钱包地址
  const agentSid = "0x" + "1".padStart(64, "0"); // 简化的SID生成
  try {
    const agentWallet = await agent.getAgentWallet(agentSid);
    console.log("分配的Agent钱包地址:", agentWallet);
  } catch (error) {
    console.log("获取Agent钱包地址失败:", error);
  }

  // 再次检查钱包地址库状态
  const poolInfoAfter = await agent.getWalletPoolInfo();
  console.log("mint后的钱包地址库信息:", {
    totalWallets: poolInfoAfter[0].toString(),
    allocatedWallets: poolInfoAfter[1].toString(),
    availableWallets: poolInfoAfter[2].toString()
  });

  console.log("测试完成！");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
