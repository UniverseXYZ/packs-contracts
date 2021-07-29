// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IPacks is IERC721 {
    function mint() external payable;
    function bulkMint(uint256 amount) external payable;
}