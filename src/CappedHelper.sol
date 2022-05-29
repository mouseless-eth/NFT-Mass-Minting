// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC721/utils/ERC721Holder.sol";
import "forge-std/console.sol";
import "./IMintableERC721.sol";

/// @title NFT mass minter 
/// @author 0xMouseLess
/// @notice This contract is used to mint NFTs in batches
contract CappedHelper is ERC721Holder {

    /// @dev NFT mint price
    uint128 immutable PRICE_PER_NFT = 0.05 ether;

    /// @dev Max mints per call 
    uint256 immutable MAX_MINT_PER_ADDRESS = 5;

    /// @notice All minting logic happens here
    constructor(IMintableERC721 target) payable {
      target.mint{value: PRICE_PER_NFT*MAX_MINT_PER_ADDRESS}(MAX_MINT_PER_ADDRESS);

      // NOTE: THIS IS NOT EFFICIENT, JUST FOR DEMO PURPOSES
      // **CAN BE REPLACED WITH A MORE EFFICIENT SOLUTION**

      uint256 counter = MAX_MINT_PER_ADDRESS;

      // Transfer nfts out one by one
      while(counter > 0) {
        uint tokenId = target.tokenOfOwnerByIndex(address(this), 0);
        target.transferFrom(address(this), msg.sender, tokenId);
        counter--;
      }
    }
}
