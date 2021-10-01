// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import 'base64-sol/base64.sol';
import 'hardhat/console.sol';

library LibPackStorage {
  bytes32 constant STORAGE_POSITION = keccak256("com.universe.packs.storage");

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

  struct Storage {
    bool initialized;

    // IERC721 pack;

    address payable daoAddress;
    bool daoInitialized;

    string _name; // Contract name
    string _symbol; // Contract symbol
    string _baseURI; // Token ID base URL (recommended as of 7/27/2021: https://arweave.net/)

    mapping (uint256 => SingleCollectible) collectibles; // Unique assets
    mapping (uint256 => Metadata) metadata; // Trait & property attributes, indexes should be coupled with 'collectibles'
    mapping (uint256 => string) licenseURI; // URL to external license or file

    uint256 collectibleCount; // Total unique assets count
    uint256 totalTokenCount; // Total NFT count to be minted
    uint256 tokenPrice;
    uint256 bulkBuyLimit;
    uint256 saleStartTime;
    bool editioned; // Display edition # in token name
    uint256 licenseVersion; // Tracker of latest license

    uint32[] shuffleIDs;
  }

  function packStorage() internal pure returns (Storage storage ds) {
    bytes32 position = STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  function random() external view returns (uint) {
    return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, packStorage().totalTokenCount)));
  }

  modifier onlyDAO() {
    require(msg.sender == packStorage().daoAddress, "Wrong address");
    _;
  }

  /**
   * Map token order w/ URI upon mints
   * Sample token ID (edition #77) with collection of 12 different assets: 1200077
   */
  function createTokenIDs(uint256 collectibleCount, uint256 editions) private {
    Storage storage ds = packStorage();

    for (uint256 i = 0; i < editions; i++) {
      ds.shuffleIDs.push(uint32((collectibleCount + 1) * 100000 + (i + 1)));
    }
  }

  function addCollectible(string[] memory _coreData, string[] memory _assets, string[][] memory _metadataValues) external onlyDAO {
    Storage storage ds = packStorage();

    ds.collectibles[ds.collectibleCount] = SingleCollectible({
      title: _coreData[0],
      description: _coreData[1],
      count: safeParseInt(_coreData[2]),
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

    ds.metadata[ds.collectibleCount] = Metadata({
      name: propertyNames,
      value: propertyValues,
      modifiable: modifiables,
      propertyCount: _metadataValues.length
    });

    uint256 editions = safeParseInt(_coreData[2]);
    createTokenIDs(ds.collectibleCount, editions);

    ds.collectibleCount++;
    ds.totalTokenCount += editions;
  }

  // Modify property field only if marked as updateable
  function updateMetadata(uint256 collectibleId, uint256 propertyIndex, string memory value) public onlyDAO {
    Storage storage ds = packStorage();
    require(ds.metadata[collectibleId - 1].modifiable[propertyIndex], 'Not allowed');
    ds.metadata[collectibleId - 1].value[propertyIndex] = value;
  }

  // Add new asset, does not automatically increase current version
  function addVersion(uint256 collectibleNumber, string memory asset) public onlyDAO {
    Storage storage ds = packStorage();
    ds.collectibles[collectibleNumber - 1].assets[ds.collectibles[collectibleNumber - 1].totalVersionCount - 1] = asset;
    ds.collectibles[collectibleNumber - 1].totalVersionCount++;
  }

  // Set version number, index starts at version 1, collectible 1 (so shifts 1 for 0th index)
  function updateVersion(uint256 collectibleNumber, uint256 versionNumber) public onlyDAO {
    Storage storage ds = packStorage();

    require(versionNumber > 0, "Versions start at 1");
    require(versionNumber <= ds.collectibles[collectibleNumber - 1].assets.length, "Versions must be less than asset count");
    require(collectibleNumber > 0, "Collectible IDs start at 1");
    ds.collectibles[collectibleNumber - 1].currentVersion = versionNumber;
  }

  // Adds new license and updates version to latest
  function addNewLicense(string memory _license) public onlyDAO {
    Storage storage ds = packStorage();
    ds.licenseURI[ds.licenseVersion] = _license;
    ds.licenseVersion++;
  }

  // Returns license URI
  function getLicense() public view returns (string memory) {
    Storage storage ds = packStorage();
    return ds.licenseURI[ds.licenseVersion - 1];
  }

  // Returns license version count
  function getLicenseVersion(uint256 versionNumber) public view returns (string memory) {
    Storage storage ds = packStorage();
    return ds.licenseURI[versionNumber - 1];
  }

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

  function tokenURI(uint256 tokenId) public view returns (string memory) {
    Storage storage ds = packStorage();

    uint256 edition = safeParseInt(substring(toString(tokenId), bytes(toString(tokenId)).length - 5, bytes(toString(tokenId)).length)) - 1;
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
                ds.editioned ? toString(edition + 1) : '',
                '", "description":"',
                ds.collectibles[collectibleId].description,
                '", "image": "',
                ds._baseURI,
                ds.collectibles[collectibleId].assets[ds.collectibles[collectibleId].currentVersion - 1],
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
