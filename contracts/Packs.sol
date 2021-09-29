// SPDX-License-Identifier: MIT
// Written by Tim Kang <> illestrater
// Thought innovation by Monstercat
// Product by universe.xyz

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* 
 * TODO:
 * Event Emitters
 * Sale start time & read-only function that checks if sale started
 * Mint Pass presale
 */

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./ConversionLibrary.sol";
import 'base64-sol/base64.sol';
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IPacks.sol";
import "hardhat/console.sol";

contract Packs is IPacks, ERC721, ReentrancyGuard {
  using SafeMath for uint256;
  using ConversionLibrary for *;

  address payable public daoAddress;
  bool private daoInitialized;

  string private _name; // Contract name
  string private _symbol; // Contract symbol
  string private _baseURI; // Token ID base URL (recommended as of 7/27/2021: https://arweave.net/)

  struct SingleCollectible {
    string title; // Collectible name
    string description; // Collectible description
    uint256 count; // Amount of editions per collectible
    string[] assets; // Each asset in array is a version
    uint256 totalVersionCount; // Total number of existing states
    uint256 currentVersion; // Current existing state
  }

  struct Metadata {
    string[] name; // Trait or attribute property field name
    string[] value; // Trait or attribute property value
    bool[] modifiable; // Can owner modify the value of field
    uint256 propertyCount; // Tracker of total attributes
  }

  mapping (uint256 => SingleCollectible) private collectibles; // Unique assets
  mapping (uint256 => Metadata) private metadata; // Trait & property attributes, indexes should be coupled with 'collectibles'
  mapping (uint256 => string) private licenseURI; // URL to external license or file

  uint256 private collectibleCount = 0; // Total unique assets count
  uint256 private totalTokenCount = 0; // Total NFT count to be minted
  uint256 private tokenPrice;
  uint256 private bulkBuyLimit;
  uint256 private saleStartTime;
  bool private editioned; // Display edition # in token name
  uint256 private licenseVersion; // Tracker of latest license

  uint32[] private shuffleIDs;

  constructor(
    string memory name,
    string memory symbol,
    string memory baseURI,
    bool _editioned,
    uint256[] memory _initParams,
    string memory _licenseURI
  ) ERC721(name, symbol) public {
    require(_initParams[1] <= 50, "Limit of 50");

    daoAddress = msg.sender;
    daoInitialized = false;

    _name = name;
    _symbol = symbol;
    _baseURI = baseURI;

    editioned = _editioned;
    tokenPrice = _initParams[0];
    bulkBuyLimit = _initParams[1];
    saleStartTime = _initParams[2];
    licenseURI[0] = _licenseURI;
    licenseVersion = 1;

    _setBaseURI(baseURI);
  }

  modifier onlyDAO() {
    require(msg.sender == daoAddress, "Wrong address");
    _;
  }

  function transferDAOownership(address payable _daoAddress) public onlyDAO {
    daoAddress = _daoAddress;
    daoInitialized = true;
  }

  function random() private view returns (uint) {
    return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, totalTokenCount)));
  }

  // Add single collectible asset with main info and metadata properties
  function addCollectible(string[] memory _coreData, string[] memory _assets, string[][] memory _metadataValues) public onlyDAO {
    collectibles[collectibleCount] = SingleCollectible({
      title: _coreData[0],
      description: _coreData[1],
      count: _coreData[2].safeParseInt(),
      assets: _assets,
      currentVersion: 1,
      totalVersionCount: _assets.length
    });

    string[] memory propertyNames = new string[](_metadataValues.length);
    string[] memory propertyValues = new string[](_metadataValues.length);
    bool[] memory modifiables = new bool[](_metadataValues.length);
    for (uint256 i = 0; i < _metadataValues.length; i++) {
      propertyNames[i] = _metadataValues[i][0];
      propertyValues[i] = _metadataValues[i][1];
      modifiables[i] = (keccak256(abi.encodePacked((_metadataValues[i][2]))) == keccak256(abi.encodePacked(('1')))); // 1 is modifiable, 0 is permanent
    }

    metadata[collectibleCount] = Metadata({
      name: propertyNames,
      value: propertyValues,
      modifiable: modifiables,
      propertyCount: _metadataValues.length
    });

    uint256 editions = _coreData[2].safeParseInt();
    createTokenIDs(collectibleCount, editions);

    collectibleCount++;
    totalTokenCount += editions;
  }

  function bulkAddCollectible(string[][] memory _coreData, string[][] memory _assets, string[][][] memory _metadataValues) public onlyDAO {
    for (uint256 i = 0; i < _coreData.length; i++) {
      addCollectible(_coreData[i], _assets[i], _metadataValues[i]);
    }
  }

  /**
   * Map token order w/ URI upon mints
   * Sample token ID (edition #77) with collection of 12 different assets: 1200077
   */
  function createTokenIDs(uint256 collectibleCount, uint256 editions) private {
    for (uint256 i = 0; i < editions; i++) {
      shuffleIDs.push(uint32((collectibleCount + 1) * 100000 + (i + 1)));
    }
  }

  function mint() public override payable nonReentrant {
    if (daoInitialized) {
      (bool transferToDaoStatus, ) = daoAddress.call{value:tokenPrice}("");
      require(transferToDaoStatus, "Address: unable to send value, recipient may have reverted");
    }

    uint256 excessAmount = msg.value.sub(tokenPrice);
    if (excessAmount > 0) {
      (bool returnExcessStatus, ) = _msgSender().call{value: excessAmount}("");
      require(returnExcessStatus, "Failed to return excess.");
    }

    uint256 randomTokenID = random() % shuffleIDs.length;
    uint256 tokenID = shuffleIDs[randomTokenID];

    shuffleIDs[randomTokenID] = shuffleIDs[shuffleIDs.length - 1];
    shuffleIDs.pop();

    _mint(_msgSender(), tokenID);
  }

  // Modify property field only if marked as updateable
  function updateMetadata(uint256 collectibleId, uint256 propertyIndex, string memory value) public onlyDAO {
    require(metadata[collectibleId - 1].modifiable[propertyIndex], 'Not allowed');
    metadata[collectibleId - 1].value[propertyIndex] = value;
  }

  // Add new asset, does not automatically increase current version
  function addVersion(uint256 collectibleNumber, string memory asset) public onlyDAO {
    collectibles[collectibleNumber - 1].assets[collectibles[collectibleNumber - 1].totalVersionCount - 1] = asset;
    collectibles[collectibleNumber - 1].totalVersionCount++;
  }

  // Set version number, index starts at version 1, collectible 1 (so shifts 1 for 0th index)
  function updateVersion(uint256 collectibleNumber, uint256 versionNumber) public onlyDAO {
    collectibles[collectibleNumber - 1].currentVersion = versionNumber - 1;
  }

  // Dynamic base64 encoded metadata generation using on-chain metadata and edition numbers
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    uint256 edition = tokenId.toString().substring(bytes(tokenId.toString()).length - 5, bytes(tokenId.toString()).length).safeParseInt() - 1;
    uint256 collectibleId = (tokenId - edition) / 100000 - 1;
    string memory encodedMetadata = '';

    for (uint i = 0; i < metadata[collectibleId].propertyCount; i++) {
      encodedMetadata = string(abi.encodePacked(
        encodedMetadata,
        '{"trait_type":"',
        metadata[collectibleId].name[i],
        '", "value":"',
        metadata[collectibleId].value[i],
        '"}',
        i == metadata[collectibleId].propertyCount - 1 ? '' : ',')
      );
    }

    string memory encoded = string(
        abi.encodePacked(
          'data:application/json;base64,',
          Base64.encode(
            bytes(
              abi.encodePacked(
                '{"name":"',
                collectibles[collectibleId].title,
                editioned ? ' #' : '',
                editioned ? (edition + 1).toString() : '',
                '", "description":"',
                collectibles[collectibleId].description,
                '", "image": "',
                _baseURI,
                collectibles[collectibleId].assets[collectibles[collectibleId].currentVersion],
                '", "attributes": [',
                encodedMetadata,
                '] }'
              )
            )
          )
        )
      );
    
    return encoded;
  }
}