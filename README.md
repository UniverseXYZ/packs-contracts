## Packs specs / functionality

### 1. Initialize a collection via constructor

- Deployment of contract initializes first collection providing baseURI, display edition #'s, NFT sale price, max bulk buy limit, sale start time, license pertaining to collection, and a free mint pass for existing holders of a different NFT collection
- Adding more collections can provide creator ability to have multiple "drops" using same contract

### 2. Add collectibles

- Adding collectibles for a collection occurs after collection is created
- Gas limit restricts to up to around 5 collectibles added with 10 metadata key/value pairs per transaction
- Metadata properties can be marked as editable by the contract owner / DAO
- Should not have more than 1000 editions of the same collectible (gas limit recommended, technically can support ~4000 editions)

### 3. User minting

- Users with whitelist / mint pass NFTs can mint 1 NFT anytime within specified duration before sale start time per defined collection
- Users without mint pass can begin minting NFTs any time after sale start time
- Token IDs are randomly distributed using on-chain randomness function. This is hard to game as it is difficult to predict when mints happen which order

### 4. Adjusting Properties

- Contract owner / DAO can adjust properties (if marked as editable) and add new versions to collectibles.
- Contract owner / DAO can add new versions of a collection's license
- Contract owner / DAO can create a new collection and begin the stages again
