pragma solidity >=0.6.0 <0.8.0;

library ConversionLibrary {
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