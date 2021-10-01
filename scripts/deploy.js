const hre = require("hardhat");
const mock = require('../test/mock-deploy.json');

async function main() {
  const collectionName = 'RELICS INSTINCT';
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
  const metadata = mock.data;

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

  let coreData = [metadata[0].coreData, metadata[1].coreData];
  let assets = [metadata[0].assets, metadata[1].assets];
  let metaData = [metadata[0].metaData, metadata[1].metaData];
  await packsInstance.bulkAddCollectible(coreData, assets, metaData);

  console.log('Metadata 1 and 2 deployed');

  coreData = [metadata[2].coreData];
  assets = [metadata[2].assets];
  metaData = [metadata[2].metaData];
  await packsInstance.bulkAddCollectible(coreData, assets, metaData);

  console.log('Metadata 3 and 4 deployed');

  await new Promise(resolve => setTimeout(resolve, 10000));

  await hre.run("verify:verify", {
    address: libraryInstance.address,
  });

  console.log('Library verified');

  await hre.run("verify:verify", {
    address: packsInstance.address,
    constructorArguments: deployArgs,
  });

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