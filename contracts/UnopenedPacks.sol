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

contract UnopenedPacks is ERC1155, ReentrancyGuard, HasSecondarySaleFees {
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  address payable public daoAddress;
  bool public daoInitialized;


  constructor(
    string memory name,
    string memory symbol,
    string memory baseURI,
    bool _editioned,
    uint256[] memory _initParams,
    string memory _licenseURI
  ) ERC721PresetMinterPauserAutoId(name, symbol, baseURI) public {
    require(_initParams[1] <= 50, "There cannot be bulk mints above 50");

    daoAddress = msg.sender;
    daoInitialized = false;

  }

  modifier onlyDAO() {
    require(msg.sender == daoAddress, "Not called from the dao");
    _;
  }

  function transferDAOownership(address payable _daoAddress) public onlyDAO {
    daoAddress = _daoAddress;
    daoInitialized = true;
  }
}