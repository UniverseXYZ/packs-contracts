// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/introspection/ERC165.sol";

contract HasSecondarySaleFees is ERC165 {
    struct Fee {
        address payable recipient;
        uint256 value;
    }

    // id => fees
    mapping (uint256 => Fee[]) public fees;
    event SecondarySaleFees(uint256 tokenId, address[] recipients, uint[] bps);

    /*
     * bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
     * bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
     *
     * => 0x0ebd4c7f ^ 0xb9c4d9fb == 0xb7799584
     */
    bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;
    constructor() public {
        _registerInterface(_INTERFACE_ID_FEES);
    }
}