# Using Smart Contracts To Mass Mint NFT Drops

Practical examples on how to **mass mint NFT drops in a single transaction** using smart contracts.

Drops vary significantly per NFT collection, this repo explores 3 differnt cases and how to approach them.

#### The 3 mint types that this repo explores are:
- NFT that perform no mint checks
- NFT that caps the mint amount per address
- NFT that does not allow smart contracts to mint

## Usage 

Install this foundry project
```shell
git clone https://github.com/mouseless-eth/NFT-Mass-Minting
cd NFT-Mass-Minting
forge install
```

Run the tests
```shell
forge test
```

#### Notice :shipit:
This repo is made only for **educational purposes**. The contracts included have been rewritten to only contain the **bare minimum needed to perfom a mass mint**. All gas saving alpha has been stripped away to improve the contracts readibility. If you want to take these to production, I highly suggest investing time into gas golfing and fine tuning your contracts.

## Mint Type One: No Checks
These type of contract's have no sanity checks and only allow users to mint **up to** a certain number of NFTs per transation. We can easily create a custom contract loops and repeatedly call the NFT's mint function.

Example of a NFT mint function that does not have any sanity checks
```solidity
function mint(uint numberOfTokens) public payable {
  uint256 ts = totalSupply();
  require(saleIsActive, "Sale must be active to mint tokens");
  require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
  require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
  require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

  for (uint256 i = 0; i < numberOfTokens; i++) {
    _safeMint(msg.sender, ts + i);
  } 
```
> [src/SimpleMinter.sol](./src/SimpleMinter.sol) contains an example of a mass minter for this type of drops 

## Mint Type Two: Capped Mint Amt Per Address
These type of contracts are more sophisticated as they track the amount minted by an address using a `mapping(address=>uint256)` which results in a **capped mint amout per address**. We can still mass mint these types of drops by using a factory design pattern to deploy multiple new contracts (new address) that do the minting.

Example of a NFT mint function that caps the mint amount per address (take note of the `minted` mapping)
```solidity
function mint(uint numberOfTokens) public payable {
  uint256 ts = totalSupply();
  require(saleIsActive, "Sale must be active to mint tokens");
  require(minted[msg.sender] + numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded account mint limit");
  require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
  require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

  minted[msg.sender] += numberOfTokens;
  for (uint256 i = 0; i < numberOfTokens; i++) {
    _safeMint(msg.sender, ts + i);
  }
}
```
> [src/CappedMinter.sol](./src/CappedMinter.sol) contains an example of a mass minter for this type of drop

###### Relevant contract files
```
src
├── CappedMinter.sol      // Factory contract to create n 'CappedHelper' instances     
├── CappedHelper.sol      // Contract that handles minting
├── IMintableERC721.sol   
├── mocks
│   ├── CappedNFT.sol          
test
├── CappedMinter.t.sol    
```

## Mint Type Three: Minter Cannot Be A Smart Contract
These type of mints make sure that only [EOA](https://ethdocs.org/en/latest/contracts-and-transactions/account-types-gas-and-transactions.html) are allowed to call the mint function. This is enforced through the following check `require(msg.sender == tx.origin)`. Because of this we cannot mass mint using a custom smart contract, but there is a work around. 

Example of a NFT mint function that only allows EOAs to mint
```solidity
function mint(uint numberOfTokens) public payable {
  uint256 ts = totalSupply();
  require(saleIsActive, "Sale must be active to mint tokens");
  require(msg.sender == tx.origin, "Contracts are not allowed to mint"); // take note of this line
  require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
  require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
  require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

  for (uint256 i = 0; i < numberOfTokens; i++) {
    _safeMint(msg.sender, ts + i);
  }
}
```
These type of drops need to be executed using a scripting languge such as **javascript**, **rust**, **python3**

#### Setup before the mint
1) Generate private keys to use
2) Seed all generated accounts with enough to pay for the total mint price
3) Each account creates a signed transation to mint the max amount from the NFT contract, save these txs in a data structure (don't broadcast the txs)
4) Sniff mempool to check if the drop is live 

#### Execution when minting is live
4) Place all signed txs in a [flashbots bundle](https://docs.flashbots.net/flashbots-auction/searchers/advanced/understanding-bundles)
5) Once the bundle has been mined, programmatically move all minted NFTs to a single address 

This works as each we are not using a smart contract and each `tx.origin` is unique. Using a flashbots bundle ensures all txs are **mined in the same block**.


*⚠️ Keeping this implementation closed sourced for now but the steps above outline how to mass mint these type of drops*

