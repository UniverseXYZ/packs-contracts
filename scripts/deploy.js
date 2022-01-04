const hre = require("hardhat");
const mock = require('../test/mock-deploy.json');

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
  const saleStartTime = Math.round((new Date()).getTime() / 1000) + mintPassDuration;
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
    mintPassOnePerWallet,
    mintPassOnly,
    mintPassFree
  ];

  let packsInstance;

  const LibPackStorage = await hre.ethers.getContractFactory("LibPackStorage");
  const libraryInstance = await LibPackStorage.deploy();
  await libraryInstance.deployed();

  console.log("Library deployed to:", libraryInstance.address);

  const Packs = await ethers.getContractFactory("Packs", {
    libraries: {
      LibPackStorage: libraryInstance.address
    },
  });

  packsInstance = await Packs.deploy(...deployArgs);
  await packsInstance.deployed();

  console.log("Packs deployed to:", packsInstance.address);

  // Add instinct metadata
  let coreData = [];
  let assets = [];
  let metaData = [];
  let secondaryMetaData = [];
  let fees = [];
  let i = 0;
  while (i < metadata.length) {
    coreData.push(metadata[i].coreData)
    assets.push(metadata[i].assets)
    metaData.push(metadata[i].metaData)
    secondaryMetaData.push(metadata[i].secondaryMetaData)
    fees.push([])
    if (i % 5 === 0) {
      await packsInstance.bulkAddCollectible(0, coreData, assets, metaData, secondaryMetaData, fees);
      coreData = [];
      assets = [];
      metaData = [];
      secondaryMetaData = [];
      fees = [];
    }

    i++;
  }

  if (coreData.length > 0) await packsInstance.bulkAddCollectible(0, coreData, assets, metaData, secondaryMetaData, fees);

  console.log('Instinct metadata deployed');

  metadata = mock.uncaged;

  const licenseURI2 = 'https://arweave.net/license';
  const editioned2 = true;
  const tokenPrice2 = ethers.utils.parseEther("0.0007");
  const bulkBuyLimit2 = 50;
  const nullAddress2 = '0x0000000000000000000000000000000000000000';
  const mintPassAddress2 = '0x9657f64f9542422c798119bbcd0f27a0baec2dcc';
  const mintPassDuration2 = 600; // 600 = 10 minutes, 3600 = 1 hour
  const mintPassOnePerWallet2 = true;
  const mintPassOnly2 = false;
  const mintPassFree2 = true;
  const saleStartTime2 = saleStartTime;
  const args = [
    baseURI,
    editioned2,
    [tokenPrice2, bulkBuyLimit2, saleStartTime2],
    licenseURI2,
    mintPassAddress2, // mintPassAddress or nullAddress for no mint pass
    mintPassDuration2,
    mintPassOnePerWallet2,
    mintPassOnly2,
    mintPassFree2
  ]

  await packsInstance.createNewCollection(...args);

  // Add uncaged metadata
  coreData = [];
  assets = [];
  metaData = [];
  secondaryMetaData = [];
  fees = [];
  i = 0;
  while (i < metadata.length) {
    coreData.push(metadata[i].coreData)
    assets.push(metadata[i].assets)
    metaData.push(metadata[i].metaData)
    secondaryMetaData.push(metadata[i].secondaryMetaData)
    fees.push([])
    if (i % 5 === 0) {
      await packsInstance.bulkAddCollectible(1, coreData, assets, metaData, secondaryMetaData, fees);
      coreData = [];
      assets = [];
      metaData = [];
      secondaryMetaData = [];
      fees = [];
    }

    i++;
  }

  if (coreData.length > 0) await packsInstance.bulkAddCollectible(1, coreData, assets, metaData, secondaryMetaData, fees);

  console.log('Uncaged metadata deployed');

  await new Promise(resolve => setTimeout(resolve, 20000));

  try {
    await hre.run("verify:verify", {
      address: libraryInstance.address,
    });
  } catch (e) {
    console.log('got error', e);
  }

  console.log('Library verified');

  try {
    await hre.run("verify:verify", {
      address: packsInstance.address,
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