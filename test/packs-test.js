const { expect } = require("chai");
const { utils } = require('ethers');
const mock = require('./mock-metadata.json');

function base64toJSON(string) {
  return JSON.parse(Buffer.from(string.replace('data:application/json;base64,',''), 'base64').toString())
}

/* TODO: Sale Start Time */

describe("Packs Test", function() {
  const baseURI = 'https://arweave.net/';
  const tokenPrice = ethers.utils.parseEther("0.0777");
  const bulkBuyLimit = 30;
  const saleStartTime = 1948372;
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
    const Packs = await ethers.getContractFactory("Packs");
    packsInstance = await Packs.deploy(
      'Relics',
      'MONSTERCAT',
      baseURI,
      true,
      [tokenPrice, bulkBuyLimit, saleStartTime],
      'https://arweave.net/license',
    );
    await packsInstance.deployed();
  });

  it("should create collectible", async function() {
    await packsInstance.addCollectible(metadata[0].coreData, metadata[0].assets, metadata[0].metaData);
  });

  it("should bulk add collectible", async function() {
    const coreData = [metadata[1].coreData, metadata[2].coreData];
    const assets = [metadata[1].assets, metadata[2].assets];
    const metaData = [metadata[1].metaData, metadata[2].metaData];
    await packsInstance.bulkAddCollectible(coreData, assets, metaData);
  });

  // it("should match the total token count", async function() {
  //   expect((await packsInstance.totalTokenCount())).to.equal(totalTokenCount);
  // });

  it("should mint one token", async function() {
    await packsInstance.functions['mint()']({value: tokenPrice})
    // expect((await packsInstance.getTokens()).length).to.equal(totalTokenCount - 1);
  });

  it("should reject mints with insufficient funds", async function() {
    expect(packsInstance.functions['mint()']({value: tokenPrice.div(2) })).to.be.reverted;
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
    await packsInstance.updateVersion(1, 4);
    const tokenJSON = base64toJSON(await packsInstance.tokenURI(100008));
    expect(tokenJSON.image).to.equal(`${ baseURI }fourrrrrrr`);
  })

  /* TODO: Write test to check non-editioned names */
});
