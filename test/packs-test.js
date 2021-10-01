const { expect } = require("chai");
const { utils } = require('ethers');
const mock = require('./mock-metadata.json');

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
      mintPassDuration
    );
    await packsInstance.deployed();
  });

  /* TODO: ONLY DAO CHECK */
  it("should create collectible", async function() {
    const fees = [[randomWallet1.address, feeSplit1], [randomWallet2.address, feeSplit2]];
    await packsInstance.addCollectible(metadata[0].coreData, metadata[0].assets, metadata[0].metaData);
  });

  it("should bulk add collectible", async function() {
    const coreData = [metadata[1].coreData, metadata[2].coreData];
    const assets = [metadata[1].assets, metadata[2].assets];
    const metaData = [metadata[1].metaData, metadata[2].metaData];
    const fees = [
      [[randomWallet2.address, feeSplit1], [randomWallet1.address, feeSplit2]],
      [[randomWallet1.address, feeSplit2], [randomWallet2.address, feeSplit1]]
    ];
    await packsInstance.bulkAddCollectible(coreData, assets, metaData);
  });

  // it("should match the total token count", async function() {
  //   expect((await packsInstance.totalTokenCount())).to.equal(totalTokenCount);
  // });

  it("should mint one token", async function() {
    await ethers.provider.send('evm_setNextBlockTimestamp', [saleStartTime]);
    await ethers.provider.send('evm_mine');
    await packsInstance.functions['mint()']({value: tokenPrice})
    // expect((await packsInstance.getTokens()).length).to.equal(totalTokenCount - 1);
  });

  it("should reject mints with insufficient funds", async function() {
    expect(packsInstance.functions['mint()']({value: tokenPrice.div(2) })).to.be.reverted;
    expect(packsInstance.bulkMint(50, {value: tokenPrice.mul(49) })).to.be.reverted;
  });

  it("should bulk mint all tokens", async function() {
    const bulkCount = Number(metadata[2].coreData[2]);
    expect(packsInstance.bulkMint(10000, {value: tokenPrice.mul(10000) })).to.be.reverted;

    await packsInstance.bulkMint(bulkCount, {value: tokenPrice.mul(bulkCount) });
    // expect((await packsInstance.getTokens()).length).to.equal(totalTokenCount - 1 - bulkCount);

    await packsInstance.bulkMint(totalTokenCount - 1 - bulkCount, {value: tokenPrice.mul(totalTokenCount - 1 - bulkCount) });
    // expect((await packsInstance.getTokens()).length).to.equal(0);

    const [owner] = await ethers.getSigners();
    expect(await packsInstance.ownerOf(100001)).to.equal(owner.address);
  });

  it("metadata should match and be updated", async function() {
    const yo = await packsInstance.tokenURI(100008);
    const tokenJSON = base64toJSON(yo);
    expect(tokenJSON.name).to.equal(`${ metadata[0].coreData[0] } #8`);
    expect(tokenJSON.description).to.equal(metadata[0].coreData[1]);
    expect(tokenJSON.image).to.equal(`${ baseURI }one`);
    expect(tokenJSON.attributes[0].trait_type).to.equal(metadata[0].metaData[0][0]);
    expect(tokenJSON.attributes[0].value).to.equal(metadata[0].metaData[0][1]);
  });

  it ("should update metadata", async function() {
    const newMetadata = 'new new';
    await packsInstance.updateMetadata(1, 0, newMetadata);
    const tokenJSON = base64toJSON(await packsInstance.tokenURI(100008));
    expect(tokenJSON.attributes[0].trait_type).to.equal(metadata[0].metaData[0][0]);
    expect(tokenJSON.attributes[0].value).to.equal(newMetadata);
  });

  it ("should not be able to update permanent metadata", async function() {
    expect(packsInstance.updateMetadata(1, 1, 'should not update')).to.be.reverted;
  });

  it("should update image asset and version", async function() {
    await packsInstance.addVersion(1, 'fourrrrrrr');
    await packsInstance.updateVersion(1, 3);
    const tokenJSON = base64toJSON(await packsInstance.tokenURI(100008));
    expect(tokenJSON.image).to.equal(`${ baseURI }fourrrrrrr`);
  });

  it("should add new license version", async function() {
    const license = await packsInstance.getLicense();
    expect(license).to.equal('https://arweave.net/license');

    await packsInstance.addNewLicense('https://arweave.net/new-license');
    const updatedLicense = await packsInstance.getLicense();
    expect(updatedLicense).to.equal('https://arweave.net/new-license');
  });

  it("should have original license", async function() {
    const license = await packsInstance.getLicenseVersion(1);
    expect(license).to.equal('https://arweave.net/license');
  })

  /* TODO: Write test to check non-editioned names */
});
