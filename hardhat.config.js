require("@nomiclabs/hardhat-waffle");
require('dotenv').config({path: __dirname+'/.env'})
require("@nomicfoundation/hardhat-verify");
require('hardhat-contract-sizer');

module.exports = {
  solidity: {
    compilers: [{
      
      version: "0.8.24",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200,
        },
      },},
      {
      
    version: "0.7.6",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },},
    {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  }]
  },
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      chainId: 1337,
      gasPrice: 225000000000,
      forking: {
         url: `https://eth-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_API_MAINNET}`, //eth
      
      },
    },
    goerli: {
      url: `https://eth-goerli.g.alchemy.com/v2/${process.env.ALCHEMY_API_GOERLI}`,
      accounts: [`0x${process.env.privateKey}`],
    },
    mumbai: {
      url: `https://polygon-mumbai.g.alchemy.com/v2/${process.env.ALCHEMY_API_MUMBAI}`,
      accounts: [`0x${process.env.privateKey}`],
    },
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_API_SEPOLIA}`,
      accounts: [`0x${process.env.privateKey}`],
    },
    testnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545/",
      chainId: 97,
      gasPrice: 21000000000,
      accounts: [`0x${process.env.privateKey}`],
    },
    mainnet: {
      url: `https://eth-mainnet.alchemyapi.io/v2/${process.env.ALCHEMY_API_MAINNET}`,
      accounts: [`0x${process.env.privateKey}`],
    },
  },

  etherscan: {
    apiKey: `${process.env.ETHERSCAN_API_KEY}`  //ETH

  },
  mocha: {
    timeout: 1000000
  }
};
