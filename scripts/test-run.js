const hre = require("hardhat");
// const { LedgerSigner } = require("@ethersproject/hardware-wallets");    
const mock = require('../test/mock-deploy.json');

function base64toJSON(string) {
  return JSON.parse(Buffer.from(string.replace('data:application/json;base64,',''), 'base64').toString())
}

async function main() {
  // MINT TEST TICKETS
  let ERC721 = await hre.ethers.getContractFactory("ERC721Mock");
  const nftInstance = await ERC721.deploy('TICKET', 'TICKET');
  await nftInstance.deployed();

  console.log("ERC721 deployed to:", nftInstance.address);

  await nftInstance.mint('0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266', 1);
  console.log('TEST TOKEN WITHOUT ENUMERABLE MINTED');

  const mintPassAddress = nftInstance.address;

  const collectionName = 'RELICS';
  const collectionSymbol = 'RELICS';
  const baseURI = 'https://arweave.net/';
  const licenseURI = 'https://arweave.net/sd2WH3t1TSG0DolXDgueNdqstVFirD1HzzfvDq13iy8';
  const editioned = true;
  const tokenPrice = ethers.utils.parseEther("0.000007");
  const bulkBuyLimit = 50;
  const nullAddress = '0x0000000000000000000000000000000000000000';
  // const mintPassAddress = '0xcebcf9c6fe1366ed0d79eec6e2e44824a4c408ad';
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

  const licenseURI2 = 'https://arweave.net/sd2WH3t1TSG0DolXDgueNdqstVFirD1HzzfvDq13iy8';
  const editioned2 = true;
  const tokenPrice2 = ethers.utils.parseEther("0.000007");
  const bulkBuyLimit2 = 50;
  const nullAddress2 = '0x0000000000000000000000000000000000000000';
  // const mintPassAddress2 = '0xcebcf9c6fe1366ed0d79eec6e2e44824a4c408ad';
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
    licenseURI2,
    mintPassAddress, // mintPassAddress or nullAddress for no mint pass
    mintPassDuration2,
    mintPassParams2
  ]

  await packsInstance.createNewCollection(...args);

  console.log('Uncaged collection created');

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
    if ((i+1) % 5 === 0) {
      await packsInstance.bulkAddCollectible(0, coreData, assets, metaData, secondaryMetaData, fees);
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
    await packsInstance.bulkAddCollectible(0, coreData, assets, metaData, secondaryMetaData, fees);
    console.log('Bulk collectibles added', coreData.length);
  }

  console.log('Instinct metadata deployed');

  metadata = mock.uncaged;

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
    if ((i+1) % 5 === 0) {
      await packsInstance.bulkAddCollectible(1, coreData, assets, metaData, secondaryMetaData, fees);
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
    await packsInstance.bulkAddCollectible(1, coreData, assets, metaData, secondaryMetaData, fees);
    console.log('Bulk collectibles added', coreData.length);
  }

  console.log('Uncaged metadata deployed');

  await nftInstance.setApprovalForAll(packsInstance.address, true);
  await packsInstance.mintPack(0, 1, {value: 0 });
  const tokenIdMinted = await packsInstance.tokenByIndex(0);
  console.log('MINTED: ', tokenIdMinted);
  const toAddress = await packsInstance.ownerOf(tokenIdMinted);
  // const tokenJSON = base64toJSON(yo);
  console.log('TO: ', toAddress);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });