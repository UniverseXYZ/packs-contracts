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
import 'base64-sol/base64.sol';
import "hardhat/console.sol";
import "../interfaces/IPacks.sol";
import "../libraries/LibPacksStorage.sol";
import "../libraries/LibOwnership.sol";
import "../libraries/LibConversions.sol";
import "../libraries/LibSecondaryFees.sol";

contract PacksFacet is IPacks, ERC721, ReentrancyGuard, HasSecondarySaleFees {
  using SafeMath for uint256;
  using ConversionLibrary for *;

  constructor(
    string memory name,
    string memory symbol,
    string memory baseURI,
    bool _editioned,
    uint256[] memory _initParams,
    string memory _licenseURI
  ) ERC721(name, symbol) public {
    require(_initParams[1] <= 50, "Limit of 50");

    LibPacksStorage.Storage storage ds = LibPacksStorage.packsStorage();

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
	  // ds.pack = IERC721(name, symbol);

    ds.initialized = true;

    _setBaseURI(baseURI);
  }

  modifier onlyDAO() {
    LibPacksStorage.Storage storage ds = LibPacksStorage.packsStorage();
    require(msg.sender == ds.daoAddress, "Wrong address");
    _;
  }

  function transferDAOownership(address payable _daoAddress) public onlyDAO {
    LibPacksStorage.Storage storage ds = LibPacksStorage.packsStorage();

    ds.daoAddress = _daoAddress;
    ds.daoInitialized = true;
  }

  function random() private view returns (uint) {
    LibPacksStorage.Storage storage ds = LibPacksStorage.packsStorage();
    return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, ds.totalTokenCount)));
  }

  // Add single collectible asset with main info and metadata properties
  function addCollectible(string[] memory _coreData, string[] memory _assets, string[] memory _secondaryAssets, string[][] memory _metadataValues, Fee[] memory _fees) public onlyDAO {
    LibPacksStorage.Storage storage ds = LibPacksStorage.packsStorage();

    uint256 sum = 0;
    for (uint256 i = 0; i < _fees.length; i++) {
      require(_fees[i].recipient != address(0x0), "No recipient");
      require(_fees[i].value != 0, "Fee negative");
      ds.secondaryFees[ds.collectibleCount].push(LibPacksStorage.Fee({
        recipient: _fees[i].recipient,
        value: _fees[i].value
      }));
      sum += _fees[i].value;
    }

    require(sum < 10000, "Fee over 100%");


    ds.collectibles[ds.collectibleCount] = LibPacksStorage.SingleCollectible({
      title: _coreData[0],
      description: _coreData[1],
      count: _coreData[2].safeParseInt(),
      assets: _assets,
      currentVersion: 1,
      totalVersionCount: _assets.length,
      secondaryAssets: _secondaryAssets,
      secondaryCurrentVersion: 1,
      secondaryTotalVersionCount: _secondaryAssets.length
    });

    string[] memory propertyNames = new string[](_metadataValues.length);
    string[] memory propertyValues = new string[](_metadataValues.length);
    bool[] memory modifiables = new bool[](_metadataValues.length);
    for (uint256 i = 0; i < _metadataValues.length; i++) {
      propertyNames[i] = _metadataValues[i][0];
      propertyValues[i] = _metadataValues[i][1];
      modifiables[i] = (keccak256(abi.encodePacked((_metadataValues[i][2]))) == keccak256(abi.encodePacked(('1')))); // 1 is modifiable, 0 is permanent
    }

    ds.metadata[ds.collectibleCount] = LibPacksStorage.Metadata({
      name: propertyNames,
      value: propertyValues,
      modifiable: modifiables,
      propertyCount: _metadataValues.length
    });

    uint256 editions = _coreData[2].safeParseInt();

    /**
    * Map token order w/ URI upon mints
    * Sample token ID (edition #77) with collection of 12 different assets: 1200077
    */
    for (uint256 i = 0; i < editions; i++) {
      ds.shuffleIDs.push(uint32((ds.collectibleCount + 1) * 100000 + (i + 1)));
    }

    ds.collectibleCount++;
    ds.totalTokenCount += editions;
  }

  function bulkAddCollectible(string[][] memory _coreData, string[][] memory _assets, string[][] memory _secondaryAssets, string[][][] memory _metadataValues, Fee[][] memory _fees) public onlyDAO {
    for (uint256 i = 0; i < _coreData.length; i++) {
      addCollectible(_coreData[i], _assets[i], _secondaryAssets[i], _metadataValues[i], _fees[i]);
    }
  }

  function mint() public override payable nonReentrant {
    LibPacksStorage.Storage storage ds = LibPacksStorage.packsStorage();

    if (ds.daoInitialized) {
      (bool transferToDaoStatus, ) = ds.daoAddress.call{value:ds.tokenPrice}("");
      require(transferToDaoStatus, "Address: unable to send value, recipient may have reverted");
    }

    uint256 excessAmount = msg.value.sub(ds.tokenPrice);
    if (excessAmount > 0) {
      (bool returnExcessStatus, ) = _msgSender().call{value: excessAmount}("");
      require(returnExcessStatus, "Failed to return excess.");
    }

    uint256 randomTokenID = random() % ds.shuffleIDs.length;
    uint256 tokenID = ds.shuffleIDs[randomTokenID];

    ds.shuffleIDs[randomTokenID] = ds.shuffleIDs[ds.shuffleIDs.length - 1];
    ds.shuffleIDs.pop();

    _mint(_msgSender(), tokenID);
  }

  function bulkMint(uint256 amount) public override payable nonReentrant {
    LibPacksStorage.Storage storage ds = LibPacksStorage.packsStorage();

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
      uint256 randomTokenID = ds.shuffleIDs.length == 1 ? 0 : random() % (ds.shuffleIDs.length - 1);
      uint256 tokenID = ds.shuffleIDs[randomTokenID];
      ds.shuffleIDs[randomTokenID] = ds.shuffleIDs[ds.shuffleIDs.length - 1];
      ds.shuffleIDs.pop();

      _mint(_msgSender(), tokenID);
    }
  }

  // Dynamic base64 encoded metadata generation using on-chain metadata and edition numbers
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    LibPacksStorage.Storage storage ds = LibPacksStorage.packsStorage();

    uint256 edition = tokenId.toString().substring(bytes(tokenId.toString()).length - 5, bytes(tokenId.toString()).length).safeParseInt() - 1;
    uint256 collectibleId = (tokenId - edition) / 100000 - 1;
    string memory encodedMetadata = '';

    for (uint i = 0; i < ds.metadata[collectibleId].propertyCount; i++) {
      encodedMetadata = string(abi.encodePacked(
        encodedMetadata,
        '{"trait_type":"',
        ds.metadata[collectibleId].name[i],
        '", "value":"',
        ds.metadata[collectibleId].value[i],
        '"}',
        i == ds.metadata[collectibleId].propertyCount - 1 ? '' : ',')
      );
    }

    string memory encoded = string(
        abi.encodePacked(
          'data:application/json;base64,',
          Base64.encode(
            bytes(
              abi.encodePacked(
                '{"name":"',
                ds.collectibles[collectibleId].title,
                ds.editioned ? ' #' : '',
                ds.editioned ? (edition + 1).toString() : '',
                '", "description":"',
                ds.collectibles[collectibleId].description,
                '", "image": "',
                ds._baseURI,
                ds.collectibles[collectibleId].assets[ds.collectibles[collectibleId].currentVersion - 1],
                '", "secondaryAsset": "',
                ds._baseURI,
                ds.collectibles[collectibleId].secondaryAssets[ds.collectibles[collectibleId].secondaryCurrentVersion - 1],
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