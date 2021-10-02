// SPDX-License-Identifier: MIT
// Written by Tim Kang <> illestrater
// Thought innovation by Monstercat
// Product by universe.xyz

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* 
 * TODO: ADD SECONDARY SALE FEES
 * Event Emitters
 */

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./LibPackStorage.sol";
import "./IPacks.sol";
import 'hardhat/console.sol';

contract Packs is IPacks, ERC721, ReentrancyGuard {
  using SafeMath for uint256;

  constructor(
    string memory name,
    string memory symbol,
    string memory baseURI,
    bool _editioned,
    uint256[] memory _initParams,
    string memory _licenseURI,
    address _mintPass,
    uint256 _mintPassDuration
  ) ERC721(name, symbol) {
    require(_initParams[1] <= 50, "Limit of 50");

    LibPackStorage.Storage storage ds = LibPackStorage.packStorage();

    ds.daoAddress = msg.sender;
    ds.daoInitialized = false;
    ds.collectionCount = 1;

    ds.collection[0]._name = name;
    ds.collection[0]._symbol = symbol;
    ds.collection[0]._baseURI = baseURI;

    ds.collection[0].editioned = _editioned;
    ds.collection[0].tokenPrice = _initParams[0];
    ds.collection[0].bulkBuyLimit = _initParams[1];
    ds.collection[0].saleStartTime = _initParams[2];
    ds.collection[0].licenseURI[0] = _licenseURI;
    ds.collection[0].licenseVersion = 1;

    if (_mintPass != address(0)) {
      ds.collection[0].mintPass = true;
      ds.collection[0].mintPassContract = ERC721(_mintPass);
      ds.collection[0].mintPassDuration = _mintPassDuration;
    }

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

  function createNewCollection(
    bool _editioned,
    uint256[] memory _initParams,
    string memory _licenseURI,
    address _mintPass,
    uint256 _mintPassDuration
  ) public onlyDAO {
    LibPackStorage.Storage storage ds = LibPackStorage.packStorage();

    ds.collection[ds.collectionCount].editioned = _editioned;
    ds.collection[ds.collectionCount].tokenPrice = _initParams[0];
    ds.collection[ds.collectionCount].bulkBuyLimit = _initParams[1];
    ds.collection[ds.collectionCount].saleStartTime = _initParams[2];
    ds.collection[ds.collectionCount].licenseURI[0] = _licenseURI;
    ds.collection[ds.collectionCount].licenseVersion = 1;

    if (_mintPass != address(0)) {
      ds.collection[ds.collectionCount].mintPass = true;
      ds.collection[ds.collectionCount].mintPassContract = ERC721(_mintPass);
      ds.collection[ds.collectionCount].mintPassDuration = _mintPassDuration;
    }

    ds.collectionCount++;
  }

  function addCollectible(uint256 cID, string[] memory _coreData, string[] memory _assets, string[][] memory _metadataValues) public onlyDAO {
    LibPackStorage.addCollectible(cID, _coreData, _assets, _metadataValues);
  }

  function bulkAddCollectible(uint256 cID, string[][] memory _coreData, string[][] memory _assets, string[][][] memory _metadataValues) public onlyDAO {
    for (uint256 i = 0; i < _coreData.length; i++) {
      addCollectible(cID, _coreData[i], _assets[i], _metadataValues[i]);
    }
  }

  function checkMintPass(uint256 cID, address minter) public view returns (uint256) {
    LibPackStorage.Storage storage ds = LibPackStorage.packStorage();
    uint256 count = ds.collection[cID].mintPassContract.balanceOf(minter);
    return count;
  }

  function mint() public payable override {}
  function bulkMint(uint256 amount) public payable override {}

  function mintPack(uint256 cID) public payable nonReentrant {
    LibPackStorage.Storage storage ds = LibPackStorage.packStorage();

    bool freeClaim = false;
    if (ds.collection[cID].mintPass && !ds.collection[cID].freeClaims[msg.sender]) {
      if (checkMintPass(cID, msg.sender) > 0) {
        freeClaim = true;
        ds.collection[cID].freeClaims[msg.sender] = true;
      }
    }

    if (ds.collection[cID].mintPass) require((freeClaim && (block.timestamp > (ds.collection[cID].saleStartTime - ds.collection[cID].mintPassDuration))), "You cannot claim");
    else require((block.timestamp > ds.collection[cID].saleStartTime), "Sale has not yet started");

    if (ds.daoInitialized) {
      (bool transferToDaoStatus, ) = ds.daoAddress.call{value:ds.collection[cID].tokenPrice}("");
      require(transferToDaoStatus, "Address: unable to send value, recipient may have reverted");
    }

    if (!freeClaim) {
      uint256 excessAmount = msg.value.sub(ds.collection[cID].tokenPrice);
      if (excessAmount > 0) {
        (bool returnExcessStatus, ) = _msgSender().call{value: excessAmount}("");
        require(returnExcessStatus, "Failed to return excess.");
      }
    }

    uint256 randomTokenID = LibPackStorage.random(cID) % ds.collection[cID].shuffleIDs.length;
    uint256 tokenID = ds.collection[cID].shuffleIDs[randomTokenID];

    ds.collection[cID].shuffleIDs[randomTokenID] = ds.collection[cID].shuffleIDs[ds.collection[cID].shuffleIDs.length - 1];
    ds.collection[cID].shuffleIDs.pop();

    _mint(_msgSender(), tokenID);
  }

  function bulkMintPack(uint256 cID, uint256 amount) public payable nonReentrant {
    LibPackStorage.Storage storage ds = LibPackStorage.packStorage();

    require(amount <= ds.collection[cID].bulkBuyLimit, "Cannot bulk buy more than the preset limit");
    require(amount <= ds.collection[cID].shuffleIDs.length, "Total supply reached");
    require((block.timestamp > ds.collection[cID].saleStartTime), "Sale has not yet started");

    if (ds.daoInitialized) {
      (bool transferToDaoStatus, ) = ds.daoAddress.call{value:ds.collection[cID].tokenPrice.mul(amount)}("");
      require(transferToDaoStatus, "Address: unable to send value, recipient may have reverted");
    }

    uint256 excessAmount = msg.value.sub(ds.collection[cID].tokenPrice.mul(amount));
    if (excessAmount > 0) {
      (bool returnExcessStatus, ) = _msgSender().call{value: excessAmount}("");
      require(returnExcessStatus, "Failed to return excess.");
    }

    for (uint256 i = 0; i < amount; i++) {
      uint256 randomTokenID = ds.collection[cID].shuffleIDs.length == 1 ? 0 : LibPackStorage.random(cID) % (ds.collection[cID].shuffleIDs.length - 1);
      uint256 tokenID = ds.collection[cID].shuffleIDs[randomTokenID];
      ds.collection[cID].shuffleIDs[randomTokenID] = ds.collection[cID].shuffleIDs[ds.collection[cID].shuffleIDs.length - 1];
      ds.collection[cID].shuffleIDs.pop();

      _mint(_msgSender(), tokenID);
    }
  }

  function updateMetadata(uint256 cID, uint256 collectibleId, uint256 propertyIndex, string memory value) public onlyDAO {
    LibPackStorage.updateMetadata(cID, collectibleId, propertyIndex, value);
  }

  function addVersion(uint256 cID, uint256 collectibleNumber, string memory asset) public onlyDAO {
    LibPackStorage.addVersion(cID, collectibleNumber, asset);
  }

  function updateVersion(uint256 cID, uint256 collectibleNumber, uint256 versionNumber) public onlyDAO {
    LibPackStorage.updateVersion(cID, collectibleNumber, versionNumber);
  }

  function addNewLicense(uint256 cID, string memory _license) public onlyDAO {
    LibPackStorage.addNewLicense(cID, _license);
  }

  function getLicense(uint256 cID) public view returns (string memory) {
    return LibPackStorage.getLicense(cID);
  }

  function getLicenseVersion(uint256 cID, uint256 versionNumber) public view returns (string memory) {
    return LibPackStorage.getLicenseVersion(cID, versionNumber);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    return LibPackStorage.tokenURI(tokenId);
  }
}