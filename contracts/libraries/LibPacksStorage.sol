// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

library LibPacksStorage {
    bytes32 constant STORAGE_POSITION = keccak256("com.universe.packs.storage");

    struct SingleCollectible {
        string title; // Collectible name
        string description; // Collectible description
        uint256 count; // Amount of editions per collectible
        string[] assets; // Each asset in array is a version
        uint256 totalVersionCount; // Total number of existing states
        uint256 currentVersion; // Current existing state
        string[] secondaryAssets; // Each asset in array is a version
        uint256 secondaryTotalVersionCount; // Total number of existing states
        uint256 secondaryCurrentVersion; // Current existing state
    }

    struct Metadata {
        string[] name; // Trait or attribute property field name
        string[] value; // Trait or attribute property value
        bool[] modifiable; // Can owner modify the value of field
        uint256 propertyCount; // Tracker of total attributes
    }

    struct Fee {
        address payable recipient;
        uint256 value;
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
        mapping (uint256 => Fee[]) secondaryFees; // Trait & property attributes, indexes should be coupled with 'collectibles'
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

    function packsStorage() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}
