// SPDX-License-Identifier: MIT
// Written by Tim Kang <> illestrater
// Thought innovation by Monstercat
// Product by universe.xyz

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import './LibPackStorage.sol';

/// @title Creators can release NFTs with multiple collectibles, across multiple collections/drops, and buyers will receive a random tokenID
/// @notice This interface should be implemented by the Packs contract
/// @dev This interface should be implemented by the Packs contract
interface IPacks {

  /* 
   * cID refers to collection ID
   * Should not have more than 1000 editions of the same collectible (gas limit recommended, technically can support ~4000 editions)
  */

  /// @notice Transfers contract ownership to DAO / different address
  /// @param _daoAddress The new address
  function transferDAOownership(address payable _daoAddress) external;

  /// @notice Creates a new collection / drop (first collection is created via constructor)
  /// @param _baseURI Base URI (e.g. https://arweave.net/)
  /// @param _editioned TODO: REMOVE EDITIONED
  /// @param _initParams Initialization parameters in array [token price, bulk buy max quantity, start time of sale]
  /// @param _licenseURI Global license URI of collection / drop
  /// @param _mintPass ERC721 contract address to allow 1 free mint prior to sale start time
  /// @param _mintPassDuration Duration before sale start time allowing free mints
  function createNewCollection(string memory _baseURI, bool _editioned, uint256[] memory _initParams, string memory _licenseURI, address _mintPass, uint256 _mintPassDuration) external;
  
  function addCollectible(uint256 cID, string[] memory _coreData, string[] memory _assets, string[][] memory _metadataValues, string[][] memory _secondaryMetadata, LibPackStorage.Fee[] memory _fees) external;

  function bulkAddCollectible(uint256 cID, string[][] memory _coreData, string[][] memory _assets, string[][][] memory _metadataValues, string[][][] memory _secondaryMetadata, LibPackStorage.Fee[][] memory _fees) external;
  
  function checkMintPass(uint256 cID, address minter) external view returns (uint256);

  function mintPack(uint256 cID) external payable;

  function bulkMintPack(uint256 cID, uint256 amount) external payable;

  function remainingTokens(uint256 cID) external view returns (uint256);

  function updateMetadata(uint256 cID, uint256 collectibleId, uint256 propertyIndex, string memory value) external;

  function addVersion(uint256 cID, uint256 collectibleNumber, string memory asset) external;

  function updateVersion(uint256 cID, uint256 collectibleNumber, uint256 versionNumber) external;

  function addNewLicense(uint256 cID, string memory _license) external;

  function getLicense(uint256 cID) external view returns (string memory);

  function getLicenseVersion(uint256 cID, uint256 versionNumber) external view returns (string memory);

  function getCollectionCount() external view returns (uint256);

  function tokenURI(uint256 tokenId) external view virtual returns (string memory);

  function getFeeRecipients(uint256 tokenId) external view returns (address payable[] memory);

  function getFeeBps(uint256 tokenId) external view returns (uint256[] memory);

  function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address recipient, uint256 amount);
}