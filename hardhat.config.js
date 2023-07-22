require("@nomicfoundation/hardhat-toolbox");
// require("@openzeppelin/hardhat-upgrades");
// require("@nomiclabs/hardhat-etherscan");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  networks: {
    hardhat: {
      forking: {
        url: "https://rpc.test.siberium.net",
        blockNumber: 563390,
        //  accounts: [""],
      },
    },
    siberium_testnet: {
      url: "https://rpc.test.siberium.net",
      accounts: [""],
      gasPrice: 50000000000,
      gas: 10000000,
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.8.17",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000,
          },
        },
      },
    ],
  },
};
