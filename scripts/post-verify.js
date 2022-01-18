const hre = require("hardhat");
const mock = require('../test/mock-deploy.json');

const libraryInstance = '0x19d5a8ab67Fd68126bb8EcEC5e52670bbD6bddA1';
const packsInstance = '0x57e7Cb9Bf75B9B6e1A93Ae2dFf18802dd8172e8f';
const saleStartTime = 1642531506;

async function main() {
  const collectionName = 'RELICS TEST';
  const collectionSymbol = 'MONSTERCAT';
  const baseURI = 'https://arweave.net/';
  const licenseURI = 'https://arweave.net/license';
  const editioned = true;
  const tokenPrice = ethers.utils.parseEther("0.0007");
  const bulkBuyLimit = 50;
  const nullAddress = '0x0000000000000000000000000000000000000000';
  const mintPassAddress = '0x9657f64f9542422c798119bbcd0f27a0baec2dcc';
  const mintPassDuration = 600; // 600 = 10 minutes, 3600 = 1 hour
  const mintPassOnePerWallet = false;
  const mintPassOnly = true;
  const mintPassFree = false;
  const mintPassBurn = true;
  const mintPassParams = [mintPassOnePerWallet, mintPassOnly, mintPassFree, mintPassBurn]
  // const saleStartTime = Math.round((new Date()).getTime() / 1000) + mintPassDuration;
  let metadata = mock.instinct;

  const deployArgs = [
    collectionName,
    collectionSymbol,
    baseURI,
    editioned,
    [tokenPrice, bulkBuyLimit, saleStartTime],
    licenseURI,
    mintPassAddress, // mintPassAddress or nullAddress for no mint pass
    mintPassDuration,
    mintPassParams
  ];

  try {
    await hre.run("verify:verify", {
      address: libraryInstance,
    });
  } catch (e) {
    console.log('got error', e);
  }

  console.log('Library verified');

  try {
    await hre.run("verify:verify", {
      address: packsInstance,
      constructorArguments: deployArgs,
    });
  } catch (e) {
    console.log('got error', e);
  }

  console.log('Packs verified');
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });