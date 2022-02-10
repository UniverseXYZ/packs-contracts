require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require('hardhat-contract-sizer');
require("@nomiclabs/hardhat-etherscan");
require('dotenv').config();


// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.7.3",
    settings: {
      optimizer: {
        enabled: false,
        runs: 200,
      },
    },
  },
  networks: {
    hardhat: {
      forking: {
        url: `https://eth-mainnet.alchemyapi.io/v2/${ process.env.ALCHEMY_KEY }`,
      },
      allowUnlimitedContractSize: false
    },
    mainnet: {
      url: `https://eth-mainnet.alchemyapi.io/v2/${ process.env.ALCHEMY_KEY }`,
      accounts: [`0x${ process.env.MM_PRIVATE_KEY }`],
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${ process.env.INFURA_KEY }`,
      // url: `https://eth-rinkeby.alchemyapi.io/v2/${ process.env.ALCHEMY_RINKEBY }`,
      accounts: [`0x${ process.env.MM_PRIVATE_KEY }`],
    },
  },
  etherscan: {
    apiKey: `${ process.env.ETHERSCAN }`
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: true,
    disambiguatePaths: false,
  },
  gasReporter: {
    enabled: true
  },
  mocha: {
    timeout: 200000
  }
};
