import { ethers } from "hardhat";

async function main() {
  console.log("开始部署HyperAGI_Agent合约...");

  // 获取部署者账户
  const [deployer] = await ethers.getSigners();
  console.log("部署者地址:", deployer.address);

  // 部署Roles配置合约
  console.log("部署Roles配置合约...");
  const RolesCfg = await ethers.getContractFactory("HyperAGI_Roles_Cfg");
  const rolesCfg = await RolesCfg.deploy(deployer.address);
  await rolesCfg.waitForDeployment();
  console.log("Roles配置合约已部署:", await rolesCfg.getAddress());

  // 部署Storage合约
  console.log("部署Storage合约...");
  const Storage = await ethers.getContractFactory("HyperAGI_Storage");
  const storage = await Storage.deploy(deployer.address);
  await storage.waitForDeployment();
  console.log("Storage合约已部署:", await storage.getAddress());

  // 部署Agent合约
  console.log("部署Agent合约...");
  const Agent = await ethers.getContractFactory("HyperAGI_Agent");
  const agent = await Agent.deploy(deployer.address);
  await agent.waitForDeployment();
  console.log("Agent合约已部署:", await agent.getAddress());

  // 设置合约地址
  console.log("设置合约地址...");
  await agent.setContractAddress([
    await rolesCfg.getAddress(),
    await storage.getAddress(),
    "0x0000000000000000000000000000000000000000", // 临时地址
    "0x0000000000000000000000000000000000000000"  // 临时地址
  ]);

  // 验证Storage合约的serviceAddress设置
  const serviceAddress = await storage._serviceAddress();
  console.log("Storage合约serviceAddress:", serviceAddress);
  console.log("Agent合约地址:", await agent.getAddress());
  console.log("serviceAddress设置正确:", serviceAddress === await agent.getAddress());

  // 生成测试钱包地址
  console.log("生成测试钱包地址...");
  const testWallets = [];
  for (let i = 0; i < 3; i++) {
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

  // 设置默认转账金额
  console.log("设置默认转账金额为0.01 ETH...");
  await agent.setDefaultTransferAmount(ethers.parseEther("0.01"));

  // 向合约发送ETH
  console.log("向合约发送0.1 ETH...");
  const tx = await deployer.sendTransaction({
    to: await agent.getAddress(),
    value: ethers.parseEther("0.1")
  });
  await tx.wait();
  console.log("ETH发送成功");

  // 检查合约余额
  const contractBalance = await ethers.provider.getBalance(await agent.getAddress());
  console.log("合约余额:", ethers.formatEther(contractBalance), "ETH");

  console.log("部署完成！");
  console.log("合约地址:");
  console.log("- Roles配置:", await rolesCfg.getAddress());
  console.log("- Storage:", await storage.getAddress());
  console.log("- Agent:", await agent.getAddress());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
