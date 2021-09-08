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
    const fees = [[randomWallet1.address, feeSplit1], [randomWallet2.address, feeSplit2]];
    await packsInstance.addCollectible(metadata[0].coreData, metadata[0].assets, metadata[0].secondaryAssets, metadata[0].metaData, fees);
  });

  it("should bulk add collectible", async function() {
    const coreData = [metadata[1].coreData, metadata[2].coreData];
    const assets = [metadata[1].assets, metadata[2].assets];
    const secondaryAssets = [metadata[1].secondaryAssets, metadata[2].secondaryAssets];
    const metaData = [metadata[1].metaData, metadata[2].metaData];
    const fees = [
      [[randomWallet2.address, feeSplit1], [randomWallet1.address, feeSplit2]],
      [[randomWallet1.address, feeSplit2], [randomWallet2.address, feeSplit1]]
    ];
    await packsInstance.bulkAddCollectible(coreData, assets, secondaryAssets, metaData, fees);
  });

  it("should match the total token count", async function() {
    expect((await packsInstance.totalTokenCount())).to.equal(totalTokenCount);
  });

  it("should mint one token", async function() {
    await packsInstance.functions['mint()']({value: tokenPrice})
    expect((await packsInstance.getTokens()).length).to.equal(totalTokenCount - 1);
  });

  it("should reject mints with insufficient funds", async function() {
    expect(packsInstance.functions['mint()']({value: tokenPrice.div(2) })).to.be.reverted;
    expect(packsInstance.bulkMint(50, {value: tokenPrice.mul(49) })).to.be.reverted;
  });

  it("should bulk mint all tokens", async function() {
    const bulkCount = Number(metadata[2].coreData[2]);
    expect(packsInstance.bulkMint(10000, {value: tokenPrice.mul(10000) })).to.be.reverted;

    await packsInstance.bulkMint(bulkCount, {value: tokenPrice.mul(bulkCount) });
    expect((await packsInstance.getTokens()).length).to.equal(totalTokenCount - 1 - bulkCount);

    await packsInstance.bulkMint(totalTokenCount - 1 - bulkCount, {value: tokenPrice.mul(totalTokenCount - 1 - bulkCount) });
    expect((await packsInstance.getTokens()).length).to.equal(0);

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
    await packsInstance.updateVersion(1, 4);
    const tokenJSON = base64toJSON(await packsInstance.tokenURI(100008));
    expect(tokenJSON.image).to.equal(`${ baseURI }fourrrrrrr`);
  });

  it("should update secondary asset and version", async function() {
    await packsInstance.addSecondaryVersion(3, 'secondaryAsset3Version3');
    await packsInstance.updateSecondaryVersion(3, 3);
    const tokenJSON = base64toJSON(await packsInstance.tokenURI(300777));
    expect(tokenJSON.secondaryAsset).to.equal(`${ baseURI }secondaryAsset3Version3`);
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

  it("should return correct secondary splits", async function() {
    let recipients = await packsInstance.getFeeRecipients(100008);
    let bps = await packsInstance.getFeeBps(100008);
    expect(recipients[0]).to.equal(randomWallet1.address);
    expect(recipients[1]).to.equal(randomWallet2.address);
    expect(bps[0].toNumber()).to.equal(feeSplit1);
    expect(bps[1].toNumber()).to.equal(feeSplit2);

    recipients = await packsInstance.getFeeRecipients(200008);
    bps = await packsInstance.getFeeBps(200008);
    expect(recipients[0]).to.equal(randomWallet2.address);
    expect(recipients[1]).to.equal(randomWallet1.address);
    expect(bps[0].toNumber()).to.equal(feeSplit1);
    expect(bps[1].toNumber()).to.equal(feeSplit2);

    recipients = await packsInstance.getFeeRecipients(300008);
    bps = await packsInstance.getFeeBps(300008);
    expect(recipients[0]).to.equal(randomWallet1.address);
    expect(recipients[1]).to.equal(randomWallet2.address);
    expect(bps[0].toNumber()).to.equal(feeSplit2);
    expect(bps[1].toNumber()).to.equal(feeSplit1);
  });

  /* TODO: Write test to check non-editioned names */
});
