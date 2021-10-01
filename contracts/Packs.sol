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

    if (_mintPass != address(0)) {
      ds.mintPass = true;
      ds.mintPassContract = ERC721(_mintPass);
      ds.mintPassDuration = _mintPassDuration;
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

  function addCollectible(string[] memory _coreData, string[] memory _assets, string[][] memory _metadataValues) public onlyDAO {
    LibPackStorage.addCollectible(_coreData, _assets, _metadataValues);
  }

  function bulkAddCollectible(string[][] memory _coreData, string[][] memory _assets, string[][][] memory _metadataValues) public onlyDAO {
    for (uint256 i = 0; i < _coreData.length; i++) {
      addCollectible(_coreData[i], _assets[i], _metadataValues[i]);
    }
  }

  function checkMintPass(address minter) public view returns (uint256) {
    LibPackStorage.Storage storage ds = LibPackStorage.packStorage();
    uint256 count = ds.mintPassContract.balanceOf(minter);
    return count;
  }

  function mint() public override payable nonReentrant {
    LibPackStorage.Storage storage ds = LibPackStorage.packStorage();

    bool freeClaim = false;
    if (ds.mintPass && !ds.freeClaims[msg.sender]) {
      if (checkMintPass(msg.sender) > 0) {
        freeClaim = true;
        ds.freeClaims[msg.sender] = true;
      }
    }

    if (ds.mintPass) require((freeClaim && (block.timestamp > (ds.saleStartTime - ds.mintPassDuration))), "You cannot claim");
    else require((block.timestamp > ds.saleStartTime), "Sale has not yet started");

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
    require((block.timestamp > ds.saleStartTime), "Sale has not yet started");

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

  function updateMetadata(uint256 collectibleId, uint256 propertyIndex, string memory value) public onlyDAO {
    LibPackStorage.updateMetadata(collectibleId, propertyIndex, value);
  }

  function addVersion(uint256 collectibleNumber, string memory asset) public onlyDAO {
    LibPackStorage.addVersion(collectibleNumber, asset);
  }

  function updateVersion(uint256 collectibleNumber, uint256 versionNumber) public onlyDAO {
    LibPackStorage.updateVersion(collectibleNumber, versionNumber);
  }

  function addNewLicense(string memory _license) public onlyDAO {
    LibPackStorage.addNewLicense(_license);
  }

  function getLicense() public view returns (string memory) {
    return LibPackStorage.getLicense();
  }

  function getLicenseVersion(uint256 versionNumber) public view returns (string memory) {
    return LibPackStorage.getLicenseVersion(versionNumber);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    return LibPackStorage.tokenURI(tokenId);
  }
}