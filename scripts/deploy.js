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
  const mintPassAddress = '0x164cb8bf056ffb41e4819cbb669bd89476d81279';
  const mintPassDuration = 600; // 600 = 10 minutes, 3600 = 1 hour
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
    mintPassDuration
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
  let coreData = [metadata[0].coreData, metadata[1].coreData];
  let assets = [metadata[0].assets, metadata[1].assets];
  let metaData = [metadata[0].metaData, metadata[1].metaData];
  let secondaryMetaData = [metadata[0].secondaryMetaData, metadata[1].secondaryMetaData];
  let fees = [[],[]];
  await packsInstance.bulkAddCollectible(0, coreData, assets, metaData, secondaryMetaData, fees);

  console.log('Instinct 1 and 2 deployed');

  coreData = [metadata[2].coreData];
  assets = [metadata[2].assets];
  metaData = [metadata[2].metaData];
  secondaryMetaData = [metadata[2].secondaryMetaData];
  fees = [[]];
  await packsInstance.bulkAddCollectible(0, coreData, assets, metaData, secondaryMetaData, fees);

  console.log('Instinct 3 deployed');

  metadata = mock.uncaged;

  const licenseURI2 = 'https://arweave.net/license';
  const editioned2 = true;
  const tokenPrice2 = ethers.utils.parseEther("0.0007");
  const bulkBuyLimit2 = 50;
  const nullAddress2 = '0x0000000000000000000000000000000000000000';
  const mintPassAddress2 = '0x164cb8bf056ffb41e4819cbb669bd89476d81279';
  const mintPassDuration2 = 600; // 600 = 10 minutes, 3600 = 1 hour
  const saleStartTime2 = saleStartTime + mintPassDuration;
  const args = [
    baseURI,
    editioned2,
    [tokenPrice2, bulkBuyLimit2, saleStartTime2],
    licenseURI2,
    mintPassAddress2, // mintPassAddress or nullAddress for no mint pass
    mintPassDuration2
  ]

  await packsInstance.createNewCollection(...args);

  // Add uncaged metadata
  coreData = [metadata[0].coreData, metadata[1].coreData];
  assets = [metadata[0].assets, metadata[1].assets];
  metaData = [metadata[0].metaData, metadata[1].metaData];
  secondaryMetaData = [metadata[0].secondaryMetaData, metadata[1].secondaryMetaData];
  fees = [[],[]];
  await packsInstance.bulkAddCollectible(1, coreData, assets, metaData, secondaryMetaData, fees);

  console.log('Uncaged 1 and 2 deployed');

  coreData = [metadata[2].coreData];
  assets = [metadata[2].assets];
  metaData = [metadata[2].metaData];
  secondaryMetaData = [metadata[2].secondaryMetaData];
  fees = [[]];
  await packsInstance.bulkAddCollectible(1, coreData, assets, metaData, secondaryMetaData, fees);

  console.log('Uncaged 3 deployed');

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