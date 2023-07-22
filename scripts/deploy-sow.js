const { ethers, upgrades } = require("hardhat");

let tx;

async function main() {
  const FEE_DATA = {
    maxFeePerGas: ethers.utils.parseUnits("100", "gwei"),
    maxPriorityFeePerGas: ethers.utils.parseUnits("50", "gwei"),
  };

  // Wrap the provider so we can override fee data.
  const provider = new ethers.providers.FallbackProvider([ethers.provider], 1);
  provider.getFeeData = async () => FEE_DATA;

  const deployer = new ethers.Wallet("").connect(provider);

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // 1. SOW token
  const SowTokenFactory = await hre.ethers.getContractFactory("SOW", deployer);
  const sowToken = await SowTokenFactory.deploy();
  tx = await sowToken.initialize();
  await tx.wait();
  console.log(`SOW token address: ${sowToken.address}`);

  // return;
  // 2. SOW Library
  const SowLibraryFactory = await hre.ethers.getContractFactory("SowLibrary", deployer);
  const sowLibrary = await SowLibraryFactory.deploy();
  tx = await sowLibrary.initialize();
  await tx.wait();

  console.log(`SOW Library address: ${sowLibrary.address}`);

  // settings
  tx = await sowLibrary.setSowToken(sowToken.address);
  await tx.wait();

  tx = await sowToken.changeMinter(sowLibrary.address);
  await tx.wait();

  // 3. SOW Work Factory

  const PaperFactoryFactory = await hre.ethers.getContractFactory("TokenFactory", deployer);
  const factory = await PaperFactoryFactory.deploy();
  tx = await factory.initialize(sowLibrary.address);
  await tx.wait();
  console.log(`Paper Factory address: ${factory.address}`);

  // settings
  tx = await sowLibrary.setFactory(factory.address);
  tx.wait();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
