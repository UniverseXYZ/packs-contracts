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
import "hardhat/console.sol";
import "../interfaces/IPacks.sol";
import "../libraries/LibConversions.sol";
import "../libraries/LibPacksStorage.sol";
import "../libraries/LibSecondaryFees.sol";

contract PacksRoyaltyFacet is ReentrancyGuard, HasSecondarySaleFees {
  using SafeMath for uint256;
  using ConversionLibrary for *;

 function getFeeRecipients(uint256 tokenId) external view returns (address payable[] memory) {
    LibPacksStorage.Storage storage ds = LibPacksStorage.packsStorage();

    uint256 edition = tokenId.toString().substring(bytes(tokenId.toString()).length - 5, bytes(tokenId.toString()).length).safeParseInt() - 1;
    uint256 collectibleId = (tokenId - edition) / 100000 - 1;
    LibPacksStorage.Fee[] memory _fees = ds.secondaryFees[collectibleId];
    address payable[] memory result = new address payable[](_fees.length);
    for (uint i = 0; i < _fees.length; i++) {
      result[i] = _fees[i].recipient;
    }
    return result;
  }

  function getFeeBps(uint256 tokenId) external view returns (uint[] memory) {
    LibPacksStorage.Storage storage ds = LibPacksStorage.packsStorage();

    uint256 edition = tokenId.toString().substring(bytes(tokenId.toString()).length - 5, bytes(tokenId.toString()).length).safeParseInt() - 1;
    uint256 collectibleId = (tokenId - edition) / 100000 - 1;
    LibPacksStorage.Fee[] memory _fees = ds.secondaryFees[collectibleId];
    uint[] memory result = new uint[](_fees.length);
    for (uint i = 0; i < _fees.length; i++) {
      result[i] = _fees[i].value;
    }

    return result;
  }
}