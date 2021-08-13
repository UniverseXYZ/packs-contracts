// SPDX-License-Identifier: MIT
// Written by Tim Kang <> illestrater
// Thought innovation by Monstercat
// Product by universe.xyz

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import 'base64-sol/base64.sol';
import "./HasSecondarySaleFees.sol";
import "hardhat/console.sol";

contract UnopenedPacks is ERC1155, ReentrancyGuard, HasSecondarySaleFees {
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  address payable public daoAddress;
  bool public daoInitialized;


  constructor(
    string memory uri
  ) ERC1155(uri) public {
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

  function mint() public payable nonReentrant {
    _mint(msg.sender, 0, 1, bytes('hi'));
  }
}