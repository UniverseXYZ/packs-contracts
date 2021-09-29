// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

const mock = require('../test/mock-metadata.json');

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile 
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const baseURI = 'https://arweave.net/';
  const tokenPrice = ethers.utils.parseEther("0.0007");
  const bulkBuyLimit = 30;
  const saleStartTime = 1948372;
  const metadata = mock.data;
  const tokenCounts = [Number(metadata[0].coreData[2]), Number(metadata[1].coreData[2]), Number(metadata[2].coreData[2])];

  let totalTokenCount = 0;
  tokenCounts.forEach(e => totalTokenCount += e);

  let packsInstance;

  const Packs = await hre.ethers.getContractFactory("Packs");
  packsInstance = await Packs.deploy(
    'RELICS INSTINCT',
    'MONSTERCAT',
    baseURI,
    true,
    [tokenPrice, bulkBuyLimit, saleStartTime],
    'https://arweave.net/license',
  );
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
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
