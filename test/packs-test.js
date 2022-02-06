const { expect } = require("chai");
const { utils } = require('ethers');
const mock = require('./mock-test.json');

function base64toJSON(string) {
  return JSON.parse(Buffer.from(string.replace('data:application/json;base64,',''), 'base64').toString())
}

describe("Packs Test", async function() {
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
  const mintPassOnePerWallet = false;
  const mintPassOnly = true;
  const mintPassFree = false;
  const mintPassBurn = true;
  const mintPassParams = [mintPassOnePerWallet, mintPassOnly, mintPassFree, mintPassBurn]
  const saleStartTime = Math.round((new Date()).getTime() / 1000) + mintPassDuration;
  const metadata = mock.data;
  const tokenCounts = [Number(metadata[0].coreData[2]), Number(metadata[1].coreData[2]), Number(metadata[2].coreData[2])];

  let totalTokenCount = 0;
  tokenCounts.forEach(e => totalTokenCount += e);

  let packsInstance;
  const randomWallet1 = ethers.Wallet.createRandom();
  const randomWallet2 = ethers.Wallet.createRandom();
  const feeSplit1 = 1000;
  const feeSplit2 = 500;

  before(async () => {
    const LibPackStorage = await hre.ethers.getContractFactory("LibPackStorage");
    const libraryInstance = await LibPackStorage.deploy();
    await libraryInstance.deployed();

    const Packs = await ethers.getContractFactory("Packs", {
      libraries: {
        LibPackStorage: libraryInstance.address
      },
    });

    packsInstance = await Packs.deploy(
      collectionName,
      collectionSymbol,
      baseURI,
      editioned,
      [tokenPrice, bulkBuyLimit, saleStartTime],
      licenseURI,
      nullAddress, // mintPassAddress or nullAddress for no mint pass
      mintPassDuration,
      mintPassParams
    );
    await packsInstance.deployed();

    const Packs2 = await ethers.getContractFactory("Packs", {
      libraries: {
        LibPackStorage: libraryInstance.address
      },
    });

    packsInstance2 = await Packs2.deploy(
      collectionName,
      collectionSymbol,
      baseURI,
      editioned,
      [tokenPrice, bulkBuyLimit, saleStartTime],
      licenseURI,
      nullAddress, // mintPassAddress or nullAddress for no mint pass
      mintPassDuration,
      mintPassParams
    );
    await packsInstance2.deployed();
  });

  it("should create collectible", async function() {
    let fees = [[randomWallet1.address, feeSplit1], [randomWallet2.address, feeSplit2]];
    await packsInstance.addCollectible(0, metadata[0].coreData, metadata[0].assets, metadata[0].metaData, metadata[0].secondaryMetaData, fees);
    await packsInstance2.addCollectible(0, metadata[0].coreData, metadata[0].assets, metadata[0].metaData, metadata[0].secondaryMetaData, fees);
  });

  it("should bulk add collectible", async function() {
    const coreData = [metadata[1].coreData, metadata[2].coreData];
    const assets = [metadata[1].assets, metadata[2].assets];
    const metaData = [metadata[1].metaData, metadata[2].metaData];
    const secondaryMetaData = [metadata[1].secondaryMetaData, metadata[2].secondaryMetaData];
    let fees = [
      [[randomWallet2.address, feeSplit1], [randomWallet1.address, feeSplit2]],
      [[randomWallet1.address, feeSplit2], [randomWallet2.address, feeSplit1]]
    ];
    await packsInstance.bulkAddCollectible(0, coreData, assets, metaData, secondaryMetaData, fees);
  });

  // it("should match the total token count", async function() {
  //   expect((await packsInstance.totalTokenCount())).to.equal(totalTokenCount);
  // });

  it("should mint one token", async function() {
    await ethers.provider.send('evm_setNextBlockTimestamp', [saleStartTime]);
    await ethers.provider.send('evm_mine');
    await packsInstance.mintPack(0, 0, {value: tokenPrice });
    expect(await packsInstance.remainingTokens(0)).to.equal(59);
    // await packsInstance.functions['mint()']({value: tokenPrice})
    // expect((await packsInstance.getTokens()).length).to.equal(totalTokenCount - 1);
  });

  it("should reject mints with insufficient funds", async function() {
    expect(packsInstance.mintPack(0, 0, {value: tokenPrice.div(2) })).to.be.reverted;
    expect(packsInstance.bulkMintPack(0, 50, {value: tokenPrice.mul(49) })).to.be.reverted;
  });

  it("should bulk mint all tokens", async function() {
    const bulkCount = Number(metadata[2].coreData[2]);
    expect(packsInstance.bulkMintPack(0, 10000, {value: tokenPrice.mul(10000) })).to.be.reverted;

    await packsInstance.bulkMintPack(0, bulkCount, {value: tokenPrice.mul(bulkCount) });
    // expect((await packsInstance.getTokens()).length).to.equal(totalTokenCount - 1 - bulkCount);

    await packsInstance.bulkMintPack(0, totalTokenCount - 1 - bulkCount, {value: tokenPrice.mul(totalTokenCount - 1 - bulkCount) });
    // expect((await packsInstance.getTokens()).length).to.equal(0);

    expect(packsInstance.mintPack(0, 0, {value: tokenPrice })).to.be.reverted;

    const [owner] = await ethers.getSigners();
    expect(await packsInstance.ownerOf(100100001)).to.equal(owner.address);
    expect(await packsInstance.remainingTokens(0)).to.equal(0);
  });

  it("metadata should match and be updated", async function() {
    const yo = await packsInstance.tokenURI(100100008);
    const yo2 = await packsInstance2.tokenURI(100100008);
    const tokenJSON = base64toJSON(yo);
    console.log(tokenJSON);
    expect(tokenJSON.name).to.equal(`${ metadata[0].coreData[0] } #8`);
    expect(tokenJSON.description).to.equal(metadata[0].coreData[1]);
    expect(tokenJSON.image).to.equal(`${ baseURI }zhKl1KoFG4RSZqCRjnBudTvF27-aGDpqNv5wRSZe5-w`);
    expect(tokenJSON.attributes[0].trait_type).to.equal(metadata[0].metaData[0][0]);
    expect(tokenJSON.attributes[0].value).to.equal(metadata[0].metaData[0][1]);
  });

  it ("should update metadata", async function() {
    const newMetadata = 'new new';
    await packsInstance.updateMetadata(0, 1, 0, newMetadata);
    const tokenJSON = base64toJSON(await packsInstance.tokenURI(100100008));
    expect(tokenJSON.attributes[0].trait_type).to.equal(metadata[0].metaData[0][0]);
    expect(tokenJSON.attributes[0].value).to.equal(newMetadata);
  });

  it ("should not be able to update permanent metadata", async function() {
    expect(packsInstance.updateMetadata(0, 1, 1, 'should not update')).to.be.reverted;
  });

  it("should update image asset and version", async function() {
    await packsInstance.addVersion(0, 1, 'fourrrrrrr');
    // await packsInstance.updateVersion(0, 1, 1);
    const tokenJSON = base64toJSON(await packsInstance.tokenURI(100100008));
    expect(tokenJSON.image).to.equal(`${ baseURI }fourrrrrrr`);
  });

  it("should add new license version", async function() {
    const license = await packsInstance.getLicense(0, 1);
    expect(license).to.equal('https://arweave.net/license');

    await packsInstance.addNewLicense(0, 'https://arweave.net/new-license');
    const updatedLicense = await packsInstance.getLicense(0, 2);
    expect(updatedLicense).to.equal('https://arweave.net/new-license');
  });

  it("should have original license", async function() {
    const license = await packsInstance.getLicense(0, 1);
    expect(license).to.equal('https://arweave.net/license');
  })

  it("should return correct rarible secondary splits", async function() {
    let recipients = await packsInstance.getFeeRecipients(100100001);
    let bps = await packsInstance.getFeeBps(100100001);
    expect(recipients[0]).to.equal(randomWallet1.address);
    expect(recipients[1]).to.equal(randomWallet2.address);
    expect(bps[0].toNumber()).to.equal(feeSplit1);
    expect(bps[1].toNumber()).to.equal(feeSplit2);
  });

  // SECOND COLLECTION
  const licenseURI2 = 'https://arweave.net/license';
  const editioned2 = true;
  const tokenPrice2 = ethers.utils.parseEther("0.07");
  const bulkBuyLimit2 = 50;
  const nullAddress2 = '0x0000000000000000000000000000000000000000';
  const mintPassAddress2 = '0x164cb8bf056ffb41e4819cbb669bd89476d81279';
  const mintPassOnePerWallet2 = false;
  const mintPassOnly2 = true;
  const mintPassFree2 = false;
  const mintPassBurn2 = false;
  const mintPassParams2 = [mintPassOnePerWallet2, mintPassOnly2, mintPassFree2, mintPassBurn2]
  const mintPassDuration2 = 600; // 600 = 10 minutes, 3600 = 1 hour
  const saleStartTime2 = saleStartTime + mintPassDuration;

  it("should create new collection", async function() {
    const args = [
      baseURI,
      editioned2,
      [tokenPrice2, bulkBuyLimit2, saleStartTime2],
      licenseURI2,
      nullAddress2, // mintPassAddress or nullAddress for no mint pass
      mintPassDuration2,
      mintPassParams2
    ]

    await packsInstance.createNewCollection(...args);
  })

  it("should return two collections", async function() {
    const collectionCount = await packsInstance.getCollectionCount();
    expect(collectionCount).to.equal(2);
  });

  it("should create collectible", async function() {
    const fees = [[randomWallet1.address, feeSplit1]];
    await packsInstance.addCollectible(1, metadata[0].coreData, metadata[0].assets, metadata[0].metaData, metadata[0].secondaryMetaData, fees);
  });

  it("should bulk add collectible", async function() {
    const coreData = [metadata[1].coreData, metadata[2].coreData];
    const assets = [metadata[1].assets, metadata[2].assets];
    const metaData = [metadata[1].metaData, metadata[2].metaData];
    const secondaryMetaData = [metadata[1].secondaryMetaData, metadata[2].secondaryMetaData];
    let fees = [
      [[randomWallet2.address, feeSplit1]],
      [[randomWallet1.address, feeSplit2]]
    ];
    await packsInstance.bulkAddCollectible(1, coreData, assets, metaData, secondaryMetaData, fees);
  });

  it("should mint one token", async function() {
    await ethers.provider.send('evm_setNextBlockTimestamp', [saleStartTime2]);
    await ethers.provider.send('evm_mine');
    await packsInstance.mintPack(1, 0, {value: tokenPrice2 });
    // await packsInstance.functions['mint()']({value: tokenPrice})
    // expect((await packsInstance.getTokens()).length).to.equal(totalTokenCount - 1);
  });

  it("should reject mints with insufficient funds", async function() {
    expect(packsInstance.mintPack(1, 0, {value: tokenPrice2.div(2) })).to.be.reverted;
    expect(packsInstance.bulkMintPack(1, 50, {value: tokenPrice2.mul(49) })).to.be.reverted;
  });

  it("should bulk mint all tokens", async function() {
    const bulkCount = Number(metadata[2].coreData[2]);
    expect(packsInstance.bulkMintPack(1, 10000, {value: tokenPrice2.mul(10000) })).to.be.reverted;

    await packsInstance.bulkMintPack(1, bulkCount, {value: tokenPrice2.mul(bulkCount) });
    // expect((await packsInstance.getTokens()).length).to.equal(totalTokenCount - 1 - bulkCount);

    await packsInstance.bulkMintPack(1, totalTokenCount - 1 - bulkCount, {value: tokenPrice2.mul(totalTokenCount - 1 - bulkCount) });
    // expect((await packsInstance.getTokens()).length).to.equal(0);

    const [owner] = await ethers.getSigners();
    expect(await packsInstance.ownerOf(200100001)).to.equal(owner.address);
  });

  it("should return correct EIP-2981 royalty", async function() {
    const price = 10000;
    let royaltyInfo = await packsInstance.royaltyInfo(200100001, price);
    expect(royaltyInfo[0]).to.equal(randomWallet1.address);
    expect(royaltyInfo[1].toNumber()).to.equal(price / (feeSplit1 / 100));
  });

  /* TODO: Write test to check non-editioned names */
});
