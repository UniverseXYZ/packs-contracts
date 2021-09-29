const tokenPrice = ethers.utils.parseEther("0.0777");
const bulkBuyLimit = 30;
const saleStartTime = 1948372;

module.exports = [
  'Relics',
  'MONSTERCAT',
  'https://arweave.net/',
  true,
  [tokenPrice, bulkBuyLimit, saleStartTime],
  'https://arweave.net/license',
];