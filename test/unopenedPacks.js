const { expect } = require("chai");
const { utils } = require('ethers')

describe("Unopened Packs", function() {
  const uri = 'https://bafybeicjlcwwlwgxgkwcmw5cloiypc5gqoj5rzrv56gox62lvmxhfscfga.ipfs.dweb.link/';
  const tokenPrice = ethers.utils.parseEther("0.0777");

  before(async () => {
    const UnopenedPacks = await ethers.getContractFactory("UnopenedPacks");
    packsInstance = await UnopenedPacks.deploy(uri);
    await packsInstance.deployed();
  });

  it("should create collectible", async function() {
    await packsInstance.mint();
  });
});
