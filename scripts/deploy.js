const hre = require("hardhat");
// const { LedgerSigner } = require("@ethersproject/hardware-wallets");    
const mock = require('../test/mock-deploy.json');

async function main() {
  const collectionName = 'RELICS';
  const collectionSymbol = 'RELICS';
  const baseURI = 'https://arweave.net/';
  const licenseURI = 'https://arweave.net/sd2WH3t1TSG0DolXDgueNdqstVFirD1HzzfvDq13iy8';
  const editioned = true;
  const tokenPrice = ethers.utils.parseEther("0.000007");
  const bulkBuyLimit = 50;
  const nullAddress = '0x0000000000000000000000000000000000000000';
  const mintPassAddress = '0x56c4476316ac2231a73cdaa8b0ac5331752bfd72';
  const mintPassDuration = 600; // 600 = 10 minutes, 3600 = 1 hour
  const mintPassOnePerWallet = false;
  const mintPassOnly = true;
  const mintPassFree = true;
  const mintPassBurn = true;
  const mintPassParams = [mintPassOnePerWallet, mintPassOnly, mintPassFree, mintPassBurn]
  // const saleStartTime = Math.round((new Date()).getTime() / 1000);
  const saleStartTime = 1644019200; // Jan 4th 2022, 7PM EST
  console.log('sale start time', saleStartTime);
  let metadata = mock.instinct;
  const metadataKeys = mock.metadataKeys;

  const deployArgs = [
    collectionName,
    collectionSymbol,
    baseURI,
    editioned,
    [tokenPrice, bulkBuyLimit, saleStartTime],
    metadataKeys,
    licenseURI,
    mintPassAddress, // mintPassAddress or nullAddress for no mint pass
    mintPassDuration,
    mintPassParams
  ];

  let packsInstance;

  let LibPackStorage = await hre.ethers.getContractFactory("LibPackStorage");
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
  let editions = [];
  let assets = [];
  let metaData = [];
  let fees = [];
  let i = 0;
  while (i < metadata.length) {
    coreData.push(metadata[i].coreData)
    editions.push(metadata[i].editions)
    assets.push(metadata[i].assets)
    metaData.push(metadata[i].metaData)
    fees.push([])
    if ((i+1) % 5 === 0) {
      await packsInstance.bulkAddCollectible(0, coreData, editions, assets, metaData, fees);
      console.log('Bulk collectibles added', coreData.length);
      coreData = [];
      editions = [];
      assets = [];
      metaData = [];
      secondaryMetaData = [];
      fees = [];
    }

    i++;
  }

  if (coreData.length > 0) {
    await packsInstance.bulkAddCollectible(0, coreData, editions, assets, metaData, fees);
    console.log('Bulk collectibles added', coreData.length);
  }

  console.log('Instinct metadata deployed');

  metadata = mock.uncaged;

  const licenseURI2 = 'https://arweave.net/sd2WH3t1TSG0DolXDgueNdqstVFirD1HzzfvDq13iy8';
  const editioned2 = true;
  const tokenPrice2 = ethers.utils.parseEther("0.000007");
  const bulkBuyLimit2 = 50;
  const nullAddress2 = '0x0000000000000000000000000000000000000000';
  const mintPassAddress2 = '0xcebcf9c6fe1366ed0d79eec6e2e44824a4c408ad';
  const mintPassDuration2 = 60; // 600 = 10 minutes, 3600 = 1 hour
  const mintPassOnePerWallet2 = false;
  const mintPassOnly2 = true;
  const mintPassFree2 = true;
  const mintPassBurn2 = true;
  const mintPassParams2 = [mintPassOnePerWallet2, mintPassOnly2, mintPassFree2, mintPassBurn2]
  const saleStartTime2 = saleStartTime;
  const args = [
    baseURI,
    editioned2,
    [tokenPrice2, bulkBuyLimit2, saleStartTime2],
    metadataKeys,
    licenseURI2,
    mintPassAddress2, // mintPassAddress or nullAddress for no mint pass
    mintPassDuration2,
    mintPassParams2
  ]

  await packsInstance.createNewCollection(...args);

  // Add uncaged metadata
  coreData = [];
  editions = [];
  assets = [];
  metaData = [];
  secondaryMetaData = [];
  fees = [];
  i = 0;
  while (i < metadata.length) {
    coreData.push(metadata[i].coreData)
    editions.push(metadata[i].editions);
    assets.push(metadata[i].assets)
    metaData.push(metadata[i].metaData)
    secondaryMetaData.push(metadata[i].secondaryMetaData)
    fees.push([])
    if ((i+1) % 5 === 0) {
      await packsInstance.bulkAddCollectible(1, coreData, editions, assets, metaData, fees);
      console.log('Bulk collectibles added', coreData.length);
      coreData = [];
      assets = [];
      metaData = [];
      secondaryMetaData = [];
      fees = [];
    }

    i++;
  }

  if (coreData.length > 0) {
    await packsInstance.bulkAddCollectible(1, coreData, editions, assets, metaData, fees);
    console.log('Bulk collectibles added', coreData.length);
  }

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