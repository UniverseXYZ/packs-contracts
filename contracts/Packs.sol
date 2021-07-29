// SPDX-License-Identifier: MIT
// Written by Tim Kang <> illestrater
// Thought innovation by Monstercat
// Product by universe.xyz

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* TODO: ADD SECONDARY SALE FEES */

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import 'base64-sol/base64.sol';
import "./ERC721PresetMinterPauserAutoId.sol";
import "./IPacks.sol";
import "./HasSecondarySaleFees.sol";
import "hardhat/console.sol";

contract Packs is IPacks, ERC721PresetMinterPauserAutoId, ReentrancyGuard, HasSecondarySaleFees {
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  address payable public daoAddress;
  bool public daoInitialized;

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
    string[] secondaryAssets; // Each asset in array is a version
    uint256 secondaryTotalVersionCount; // Total number of existing states
    uint256 secondaryCurrentVersion; // Current existing state
  }

  struct Metadata {
    string[] name; // Trait or attribute property field name
    string[] value; // Trait or attribute property value
    bool[] modifiable; // Can owner modify the value of field
    uint256 propertyCount; // Tracker of total attributes
  }

  mapping (uint256 => SingleCollectible) collectibles; // Unique assets
  mapping (uint256 => Metadata) metadata; // Trait & property attributes, indexes should be coupled with 'collectibles'
  mapping (uint256 => Fee[]) secondaryFees; // Trait & property attributes, indexes should be coupled with 'collectibles'
  mapping (uint256 => string) public licenseURI; // URL to external license or file

  uint256 public collectibleCount = 0; // Total unique assets count
  uint256 public totalTokenCount = 0; // Total NFT count to be minted
  uint256 public tokenPrice;
  uint256 public bulkBuyLimit;
  uint256 public saleStartTime;
  bool public editioned; // Display edition # in token name
  uint256 public licenseVersion; // Tracker of latest license

  uint256[] public shuffleIDs;

  constructor(
    string memory name,
    string memory symbol,
    string memory baseURI,
    bool _editioned,
    uint256[] memory _initParams,
    string memory _licenseURI
  ) ERC721PresetMinterPauserAutoId(name, symbol, baseURI) public {
    require(_initParams[1] <= 30, "There cannot be bulk mints above 100");

    daoAddress = msg.sender;
    daoInitialized = false;

    _name = name;
    _symbol = symbol;
    _baseURI  = baseURI;

    editioned = _editioned;
    tokenPrice = _initParams[0];
    bulkBuyLimit = _initParams[1];
    saleStartTime = _initParams[2];
    licenseURI[0] = _licenseURI;
    licenseVersion = 1;
  }

  modifier onlyDAO() {
    require(msg.sender == daoAddress, "Not called from the dao");
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
  function addCollectible(string[] memory _coreData, string[] memory _assets, string[] memory _secondaryAssets, string[][] memory _metadataValues, Fee[] memory _fees) public onlyDAO {
    uint256 sum = 0;
    for (uint256 i = 0; i < _fees.length; i++) {
      require(_fees[i].recipient != address(0x0), "Recipient should be present");
      require(_fees[i].value != 0, "Fee value should be positive");
      secondaryFees[collectibleCount].push(Fee({
        recipient: _fees[i].recipient,
        value: _fees[i].value
      }));
      sum += _fees[i].value;
    }

    require(sum < 10000, "Fee should be less than 100%");

    collectibles[collectibleCount] = SingleCollectible({
      title: _coreData[0],
      description: _coreData[1],
      count: safeParseInt(_coreData[2]),
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

    metadata[collectibleCount] = Metadata({
      name: propertyNames,
      value: propertyValues,
      modifiable: modifiables,
      propertyCount: _metadataValues.length
    });

    uint256 editions = safeParseInt(_coreData[2]);
    createTokenIDs(collectibleCount, editions);

    collectibleCount++;
    totalTokenCount += editions;
  }

  function bulkAddCollectible(string[][] memory _coreData, string[][] memory _assets, string[][] memory _secondaryAssets, string[][][] memory _metadataValues, Fee[][] memory _fees) public onlyDAO {
    for (uint256 i = 0; i < _coreData.length; i++) {
      addCollectible(_coreData[i], _assets[i], _secondaryAssets[i], _metadataValues[i], _fees[i]);
    }
  }

  /**
   * Map token order w/ URI upon mints
   * Sample token ID (edition #77) with collection of 12 different assets: 1200077
   */
  function createTokenIDs(uint256 collectibleCount, uint256 editions) private {
    for (uint256 i = 0; i < editions; i++) {
      shuffleIDs.push((collectibleCount + 1) * 100000 + (i + 1));
    }
  }

  function getTokens() public view returns (uint256[] memory) {
    return shuffleIDs;
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

    uint256 randomTokenID = random() % (shuffleIDs.length - 1);
    uint256 tokenID = shuffleIDs[randomTokenID];
    shuffleIDs[randomTokenID] = shuffleIDs[shuffleIDs.length - 1];
    shuffleIDs.pop();

    _mint(_msgSender(), tokenID);
  }

  function bulkMint(uint256 amount) public override payable nonReentrant {
    require(amount <= bulkBuyLimit, "Cannot bulk buy more than the preset limit");
    require(amount <= shuffleIDs.length, "Total supply reached");

    if (daoInitialized) {
      (bool transferToDaoStatus, ) = daoAddress.call{value:tokenPrice.mul(amount)}("");
      require(transferToDaoStatus, "Address: unable to send value, recipient may have reverted");
    }

    uint256 excessAmount = msg.value.sub(tokenPrice.mul(amount));
    if (excessAmount > 0) {
      (bool returnExcessStatus, ) = _msgSender().call{value: excessAmount}("");
      require(returnExcessStatus, "Failed to return excess.");
    }

    for (uint256 i = 0; i < amount; i++) {
      uint256 randomTokenID = shuffleIDs.length == 1 ? 0 : random() % (shuffleIDs.length - 1);
      uint256 tokenID = shuffleIDs[randomTokenID];
      shuffleIDs[randomTokenID] = shuffleIDs[shuffleIDs.length - 1];
      shuffleIDs.pop();

      _mint(_msgSender(), tokenID);
    }
  }

  // Modify property field only if marked as updateable
  function updateMetadata(uint256 collectibleId, uint256 propertyIndex, string memory value) public onlyDAO {
    require(metadata[collectibleId - 1].modifiable[propertyIndex], 'Metadata field not updateable');
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

  // Secondary asset versioning
  function updateSecondaryVersion(uint256 collectibleNumber, uint256 versionNumber) public onlyDAO {
    collectibles[collectibleNumber - 1].secondaryCurrentVersion = versionNumber - 1;
  }

  function addSecondaryVersion(uint256 collectibleNumber, string memory asset) public onlyDAO {
    collectibles[collectibleNumber - 1].secondaryAssets[collectibles[collectibleNumber - 1].secondaryTotalVersionCount - 1] = asset;
    collectibles[collectibleNumber - 1].secondaryTotalVersionCount++;
  }

  // Adds new license and updates version to latest
  function addNewLicense(string memory _license) public onlyDAO {
    licenseURI[licenseVersion] = _license;
    licenseVersion++;
  }

  // Returns license URI
  function getLicense() public view returns (string memory) {
    return licenseURI[licenseVersion - 1];
  }

  // Returns license version count
  function getLicenseVersion(uint256 versionNumber) public view returns (string memory) {
    return licenseURI[versionNumber - 1];
  }

  function getFeeRecipients(uint256 tokenId) external view returns (address payable[] memory) {
    uint256 edition = safeParseInt(substring(toString(tokenId), bytes(toString(tokenId)).length - 5, bytes(toString(tokenId)).length)) - 1;
    uint256 collectibleId = (tokenId - edition) / 100000 - 1;
    Fee[] memory _fees = secondaryFees[collectibleId];
    address payable[] memory result = new address payable[](_fees.length);
    for (uint i = 0; i < _fees.length; i++) {
      result[i] = _fees[i].recipient;
    }
    return result;
  }

  function getFeeBps(uint256 tokenId) external view returns (uint[] memory) {
    uint256 edition = safeParseInt(substring(toString(tokenId), bytes(toString(tokenId)).length - 5, bytes(toString(tokenId)).length)) - 1;
    uint256 collectibleId = (tokenId - edition) / 100000 - 1;
    Fee[] memory _fees = secondaryFees[collectibleId];
    uint[] memory result = new uint[](_fees.length);
    for (uint i = 0; i < _fees.length; i++) {
      result[i] = _fees[i].value;
    }

    return result;
  }

  // Dynamic base64 encoded metadata generation using on-chain metadata and edition numbers
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    string memory stringId = toString(tokenId);
    uint256 edition = safeParseInt(substring(stringId, bytes(stringId).length - 5, bytes(stringId).length)) - 1;
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
                editioned ? toString(edition + 1) : '',
                '", "description":"',
                collectibles[collectibleId].description,
                '", "image": "',
                _baseURI,
                collectibles[collectibleId].assets[collectibles[collectibleId].currentVersion - 1],
                '", "secondaryAsset": "',
                _baseURI,
                collectibles[collectibleId].secondaryAssets[collectibles[collectibleId].secondaryCurrentVersion - 1],
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

  /* HELPER FUNCTIONS
   * Functions from https://github.com/provable-things/ethereum-api/blob/master/provableAPI_0.6.sol
   */
  function toString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
        return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
        digits++;
        temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    uint256 index = digits - 1;
    temp = value;
    while (temp != 0) {
        buffer[index--] = bytes1(uint8(48 + temp % 10));
        temp /= 10;
    }
    return string(buffer);
  }

  function safeParseInt(string memory _a) internal pure returns (uint _parsedInt) {
    return safeParseInt(_a, 0);
  }

  function safeParseInt(string memory _a, uint _b) internal pure returns (uint _parsedInt) {
    bytes memory bresult = bytes(_a);
    uint mint = 0;
    bool decimals = false;
    for (uint i = 0; i < bresult.length; i++) {
      if ((uint(uint8(bresult[i])) >= 48) && (uint(uint8(bresult[i])) <= 57)) {
        if (decimals) {
            if (_b == 0) break;
            else _b--;
        }
        mint *= 10;
        mint += uint(uint8(bresult[i])) - 48;
      } else if (uint(uint8(bresult[i])) == 46) {
        require(!decimals, 'More than one decimal encountered in string!');
        decimals = true;
      } else {
        revert("Non-numeral character encountered in string!");
      }
    }
    if (_b > 0) {
      mint *= 10 ** _b;
    }
    return mint;
  }

  function substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
    bytes memory strBytes = bytes(str);
    bytes memory result = new bytes(endIndex-startIndex);
    for(uint i = startIndex; i < endIndex; i++) {
        result[i-startIndex] = strBytes[i];
    }
    return string(result);
  }
}