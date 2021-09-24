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
import "hardhat/console.sol";
import "../libraries/LibConversions.sol";
import "../libraries/LibPacksStorage.sol";

contract PacksTokenInfoFacet {
  using SafeMath for uint256;
  using ConversionLibrary for *;

  modifier onlyDAO() {
    LibPacksStorage.Storage storage ds = LibPacksStorage.packsStorage();
    require(msg.sender == ds.daoAddress, "Wrong address");
    _;
  }

  // Modify property field only if marked as updateable
  function updateMetadata(uint256 collectibleId, uint256 propertyIndex, string memory value) public onlyDAO {
    LibPacksStorage.Storage storage ds = LibPacksStorage.packsStorage();

    require(ds.metadata[collectibleId - 1].modifiable[propertyIndex], 'Not allowed');
    ds.metadata[collectibleId - 1].value[propertyIndex] = value;
  }

  // Add new asset, does not automatically increase current version
  function addVersion(uint256 collectibleNumber, string memory asset) public onlyDAO {
    LibPacksStorage.Storage storage ds = LibPacksStorage.packsStorage();
    ds.collectibles[collectibleNumber - 1].assets[ds.collectibles[collectibleNumber - 1].totalVersionCount - 1] = asset;
    ds.collectibles[collectibleNumber - 1].totalVersionCount++;
  }

  // Set version number, index starts at version 1, collectible 1 (so shifts 1 for 0th index)
  function updateVersion(uint256 collectibleNumber, uint256 versionNumber) public onlyDAO {
    LibPacksStorage.Storage storage ds = LibPacksStorage.packsStorage();

    ds.collectibles[collectibleNumber - 1].currentVersion = versionNumber - 1;
  }

  // Secondary asset versioning
  function updateSecondaryVersion(uint256 collectibleNumber, uint256 versionNumber) public onlyDAO {
    LibPacksStorage.Storage storage ds = LibPacksStorage.packsStorage();

    ds.collectibles[collectibleNumber - 1].secondaryCurrentVersion = versionNumber - 1;
  }

  function addSecondaryVersion(uint256 collectibleNumber, string memory asset) public onlyDAO {
    LibPacksStorage.Storage storage ds = LibPacksStorage.packsStorage();

    ds.collectibles[collectibleNumber - 1].secondaryAssets[ds.collectibles[collectibleNumber - 1].secondaryTotalVersionCount - 1] = asset;
    ds.collectibles[collectibleNumber - 1].secondaryTotalVersionCount++;
  }

  // Adds new license and updates version to latest
  function addNewLicense(string memory _license) public onlyDAO {
    LibPacksStorage.Storage storage ds = LibPacksStorage.packsStorage();

    ds.licenseURI[ds.licenseVersion] = _license;
    ds.licenseVersion++;
  }

  // Returns license URI
  function getLicense() public view returns (string memory) {
    LibPacksStorage.Storage storage ds = LibPacksStorage.packsStorage();

    return ds.licenseURI[ds.licenseVersion - 1];
  }

  // Returns license version count
  function getLicenseVersion(uint256 versionNumber) public view returns (string memory) {
    LibPacksStorage.Storage storage ds = LibPacksStorage.packsStorage();

    return ds.licenseURI[versionNumber - 1];
  }
}