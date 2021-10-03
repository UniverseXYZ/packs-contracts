// SPDX-License-Identifier: MIT
// Written by Tim Kang <> illestrater
// Thought innovation by Monstercat
// Product by universe.xyz

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./LibPackStorage.sol";
import 'hardhat/console.sol';

contract Packs is IERC721, ERC721, ReentrancyGuard {
  using SafeMath for uint256;

  constructor(
    string memory name,
    string memory symbol,
    string memory _baseURI,
    bool _editioned,
    uint256[] memory _initParams,
    string memory _licenseURI,
    address _mintPass,
    uint256 _mintPassDuration
  ) ERC721(name, symbol) {
    require(_initParams[1] <= 50, "Bulk buy limit of 50");

    LibPackStorage.Storage storage ds = LibPackStorage.packStorage();

    ds.daoAddress = msg.sender;
    ds.daoInitialized = false;
    ds.collectionCount = 1;

    ds.collection[0].baseURI = _baseURI;
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

    _setBaseURI(_baseURI);
  }
  
  event LogCreateNewCollection(
    uint256 index
  );

  event LogAddCollectible(
    uint256 cID,
    string title
  );

  event LogMintPack(
    address minter,
    uint256 tokenID
  );
  
  event LogUpdateMetadata(
    uint256 cID,
    uint256 collectibleId,
    uint256 propertyIndex,
    string value
  );

  event LogAddVersion(
    uint256 cID,
    uint256 collectibleId,
    string asset
  );

  event LogUpdateVersion(
    uint256 cID,
    uint256 collectibleId,
    uint256 versionNumber
  );

  event LogAddNewLicense(
    uint256 cID,
    string license
  );

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

  function createNewCollection(string memory _baseURI, bool _editioned, uint256[] memory _initParams, string memory _licenseURI, address _mintPass, uint256 _mintPassDuration) public onlyDAO {
    LibPackStorage.createNewCollection(_baseURI, _editioned, _initParams, _licenseURI, _mintPass, _mintPassDuration);
    LibPackStorage.Storage storage ds = LibPackStorage.packStorage();
    emit LogCreateNewCollection(ds.collectionCount);
  }

  /**** cID refers to collection ID ****/
  function addCollectible(uint256 cID, string[] memory _coreData, string[] memory _assets, string[][] memory _metadataValues, string[][] memory _secondaryMetadata) public onlyDAO {
    LibPackStorage.addCollectible(cID, _coreData, _assets, _metadataValues, _secondaryMetadata);
    emit LogAddCollectible(cID, _coreData[0]);
  }

  function bulkAddCollectible(uint256 cID, string[][] memory _coreData, string[][] memory _assets, string[][][] memory _metadataValues, string[][][] memory _secondaryMetadata) public onlyDAO {
    for (uint256 i = 0; i < _coreData.length; i++) {
      addCollectible(cID, _coreData[i], _assets[i], _metadataValues[i], _secondaryMetadata[i]);
    }
  }

  function checkMintPass(uint256 cID, address minter) public view returns (uint256) {
    LibPackStorage.Storage storage ds = LibPackStorage.packStorage();
    uint256 count = ds.collection[cID].mintPassContract.balanceOf(minter);
    return count;
  }

  function canFreeClaim(uint256 cID) private returns (bool)  {
    LibPackStorage.Storage storage ds = LibPackStorage.packStorage();

    bool freeClaim = false;
    if (ds.collection[cID].mintPass && !ds.collection[cID].freeClaims[msg.sender]) {
      if (checkMintPass(cID, msg.sender) > 0) {
        freeClaim = true;
        ds.collection[cID].freeClaims[msg.sender] = true;
      }
    }

    return freeClaim;
  }

  function randomTokenID(uint256 cID) private returns (uint256) {
    LibPackStorage.Storage storage ds = LibPackStorage.packStorage();

    uint256 randomTokenID = LibPackStorage.random(cID) % ds.collection[cID].shuffleIDs.length;
    uint256 tokenID = ds.collection[cID].shuffleIDs[randomTokenID];

    ds.collection[cID].shuffleIDs[randomTokenID] = ds.collection[cID].shuffleIDs[ds.collection[cID].shuffleIDs.length - 1];
    ds.collection[cID].shuffleIDs.pop();

    return tokenID;
  }

  function mintPack(uint256 cID) public payable nonReentrant {
    LibPackStorage.Storage storage ds = LibPackStorage.packStorage();
    bool freeClaim = canFreeClaim(cID);
    LibPackStorage.mintChecks(cID, freeClaim);
 
   if (!freeClaim) {
      uint256 excessAmount = msg.value.sub(ds.collection[cID].tokenPrice);
      if (excessAmount > 0) {
        (bool returnExcessStatus, ) = _msgSender().call{value: excessAmount}("");
        require(returnExcessStatus, "Failed to return excess.");
      }
    }

    uint256 tokenID = randomTokenID(cID);
    _mint(_msgSender(), tokenID);
    emit LogMintPack(msg.sender, tokenID);
  }

  function bulkMintPack(uint256 cID, uint256 amount) public payable nonReentrant {
    LibPackStorage.Storage storage ds = LibPackStorage.packStorage();

    LibPackStorage.bulkMintChecks(cID, amount);

    uint256 excessAmount = msg.value.sub(ds.collection[cID].tokenPrice.mul(amount));
    if (excessAmount > 0) {
      (bool returnExcessStatus, ) = _msgSender().call{value: excessAmount}("");
      require(returnExcessStatus, "Failed to return excess.");
    }

    for (uint256 i = 0; i < amount; i++) {
      uint256 tokenID = randomTokenID(cID);
      _mint(_msgSender(), tokenID);
      emit LogMintPack(msg.sender, tokenID);
    }
  }

  function updateMetadata(uint256 cID, uint256 collectibleId, uint256 propertyIndex, string memory value) public onlyDAO {
    LibPackStorage.updateMetadata(cID, collectibleId, propertyIndex, value);
    emit LogUpdateMetadata(cID, collectibleId, propertyIndex, value);
  }

  function addVersion(uint256 cID, uint256 collectibleNumber, string memory asset) public onlyDAO {
    LibPackStorage.addVersion(cID, collectibleNumber, asset);
    emit LogAddVersion(cID, collectibleNumber, asset);
  }

  function updateVersion(uint256 cID, uint256 collectibleNumber, uint256 versionNumber) public onlyDAO {
    LibPackStorage.updateVersion(cID, collectibleNumber, versionNumber);
    emit LogUpdateVersion(cID, collectibleNumber, versionNumber);
  }

  function addNewLicense(uint256 cID, string memory _license) public onlyDAO {
    LibPackStorage.addNewLicense(cID, _license);
    emit LogAddNewLicense(cID, _license);
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