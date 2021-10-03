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

module.exports = [
  collectionName,
  collectionSymbol,
  baseURI,
  editioned,
  [tokenPrice, bulkBuyLimit, saleStartTime],
  licenseURI,
  mintPassAddress, // mintPassAddress or nullAddress for no mint pass
  mintPassDuration
];