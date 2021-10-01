// SPDX-License-Identifier: MIT
// Written by Tim Kang <> illestrater
// Thought innovation by Monstercat
// Product by universe.xyz

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* 
 * TODO: ADD SECONDARY SALE FEES
 * Event Emitters
 * Sale start time & read-only function that checks if sale started
 * Mint Pass presale
 */

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./LibPackStorage.sol";
import "./IPacks.sol";

contract Packs is IPacks, ERC721, ReentrancyGuard {
  using SafeMath for uint256;

  Packs packs = Packs(0xD47F7521792Cca93983E447a7Cc7f55794284f78);

  constructor(
    string memory name,
    string memory symbol,
    string memory baseURI,
    bool _editioned,
    uint256[] memory _initParams,
    string memory _licenseURI
  ) ERC721(name, symbol) public {
    require(_initParams[1] <= 50, "Limit of 50");

    LibPackStorage.Storage storage ds = LibPackStorage.packStorage();

    ds.daoAddress = msg.sender;
    ds.daoInitialized = false;

    ds._name = name;
    ds._symbol = symbol;
    ds._baseURI = baseURI;

    ds.editioned = _editioned;
    ds.tokenPrice = _initParams[0];
    ds.bulkBuyLimit = _initParams[1];
    ds.saleStartTime = _initParams[2];
    ds.licenseURI[0] = _licenseURI;
    ds.licenseVersion = 1;

    _setBaseURI(baseURI);
  }

  modifier onlyDAO() {
    LibPackStorage.Storage storage ds = LibPackStorage.packStorage();
    require(msg.sender == ds.daoAddress, "Wrong address");
    _;
  }

  function transferDAOownership(address payable _daoAddress) public onlyDAO {
    LibPackStorage.Storage storage ds = LibPackStorage.packStorage();
    ds.daoAddress = _daoAddress;
    ds.daoInitialized = true;
  }

  // Add single collectible asset with main info and metadata properties
  function addCollectible(string[] memory _coreData, string[] memory _assets, string[][] memory _metadataValues) public onlyDAO {
    LibPackStorage.addCollectible(_coreData, _assets, _metadataValues);
  }

  function bulkAddCollectible(string[][] memory _coreData, string[][] memory _assets, string[][][] memory _metadataValues) public onlyDAO {
    for (uint256 i = 0; i < _coreData.length; i++) {
      addCollectible(_coreData[i], _assets[i], _metadataValues[i]);
    }
  }

  function checkMintPass(address minter) public view returns (uint256) {
    uint256 count = packs.balanceOf(minter);
    return count;
  }

  function mint() public override payable nonReentrant {
    LibPackStorage.Storage storage ds = LibPackStorage.packStorage();

    bool freeClaim = false;
    if (!ds.freeClaims[msg.sender]) {
      if (packs.balanceOf(msg.sender) > 0) {
        freeClaim = true;
        ds.freeClaims[msg.sender] = true;
      }
    }

    if (ds.daoInitialized) {
      (bool transferToDaoStatus, ) = ds.daoAddress.call{value:ds.tokenPrice}("");
      require(transferToDaoStatus, "Address: unable to send value, recipient may have reverted");
    }

    if (!freeClaim) {
      uint256 excessAmount = msg.value.sub(ds.tokenPrice);
      if (excessAmount > 0) {
        (bool returnExcessStatus, ) = _msgSender().call{value: excessAmount}("");
        require(returnExcessStatus, "Failed to return excess.");
      }
    }

    uint256 randomTokenID = LibPackStorage.random() % ds.shuffleIDs.length;
    uint256 tokenID = ds.shuffleIDs[randomTokenID];

    ds.shuffleIDs[randomTokenID] = ds.shuffleIDs[ds.shuffleIDs.length - 1];
    ds.shuffleIDs.pop();

    _mint(_msgSender(), tokenID);
  }

  function bulkMint(uint256 amount) public override payable nonReentrant {
    LibPackStorage.Storage storage ds = LibPackStorage.packStorage();

    require(amount <= ds.bulkBuyLimit, "Cannot bulk buy more than the preset limit");
    require(amount <= ds.shuffleIDs.length, "Total supply reached");

    if (ds.daoInitialized) {
      (bool transferToDaoStatus, ) = ds.daoAddress.call{value:ds.tokenPrice.mul(amount)}("");
      require(transferToDaoStatus, "Address: unable to send value, recipient may have reverted");
    }

    uint256 excessAmount = msg.value.sub(ds.tokenPrice.mul(amount));
    if (excessAmount > 0) {
      (bool returnExcessStatus, ) = _msgSender().call{value: excessAmount}("");
      require(returnExcessStatus, "Failed to return excess.");
    }

    for (uint256 i = 0; i < amount; i++) {
      uint256 randomTokenID = ds.shuffleIDs.length == 1 ? 0 : LibPackStorage.random() % (ds.shuffleIDs.length - 1);
      uint256 tokenID = ds.shuffleIDs[randomTokenID];
      ds.shuffleIDs[randomTokenID] = ds.shuffleIDs[ds.shuffleIDs.length - 1];
      ds.shuffleIDs.pop();

      _mint(_msgSender(), tokenID);
    }
  }

  // Modify property field only if marked as updateable
  function updateMetadata(uint256 collectibleId, uint256 propertyIndex, string memory value) public onlyDAO {
    LibPackStorage.updateMetadata(collectibleId, propertyIndex, value);
  }

  // Add new asset, does not automatically increase current version
  function addVersion(uint256 collectibleNumber, string memory asset) public onlyDAO {
    LibPackStorage.addVersion(collectibleNumber, asset);
  }

  // Set version number, index starts at version 1, collectible 1 (so shifts 1 for 0th index)
  function updateVersion(uint256 collectibleNumber, uint256 versionNumber) public onlyDAO {
    LibPackStorage.updateVersion(collectibleNumber, versionNumber);
  }

  // Adds new license and updates version to latest
  function addNewLicense(string memory _license) public onlyDAO {
    LibPackStorage.addNewLicense(_license);
  }

  // Returns license URI
  function getLicense() public view returns (string memory) {
    return LibPackStorage.getLicense();
  }

  // Returns license version count
  function getLicenseVersion(uint256 versionNumber) public view returns (string memory) {
    return LibPackStorage.getLicenseVersion(versionNumber);
  }

  // Dynamic base64 encoded metadata generation using on-chain metadata and edition numbers
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    return LibPackStorage.tokenURI(tokenId);
  }
}