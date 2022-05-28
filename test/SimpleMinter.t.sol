// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "../src/SimpleMinter.sol";
import "../src/mocks/SimpleNFT.sol";

/// @title Test Simple Minter contract
/// @author 0xMouseLess
contract SimpleMinterTest is Test {

  /// @notice Our mass minting contract
  SimpleMinter simpleMinter;

  /// @notice The nft we are minting
  SimpleNFT simpleNFT;

  /// @notice Mock EOA
  address minterEoa = 0xc0FFee0000000000000000000000000000000000;
  /// @notice NFT Contract Owner
  address nftOwner = 0x00000000003b3cc22aF3aE1EAc0440BcEe416B40;

  /// @notice Setup tests
  function setUp() public {
    // Deploy mock nft contract from mock owner
    vm.prank(nftOwner);
    simpleNFT = new SimpleNFT();
    // Setup all calls to happen from mock eoa
    startHoax(minterEoa, 100 ether);
    // Setup minting contract
    simpleMinter = new SimpleMinter(address(simpleNFT));
  }

  /// @notice Test massMint function when minting is live
  function testMintActive() public {
    // Enforce that the sale is active
    if(!simpleNFT.saleIsActive()) {
      changePrank(nftOwner);
      simpleNFT.setSaleState(true);
    }
    changePrank(minterEoa);
    // Number of nfts that we will mint
    uint numToMint = 30;
    // Price per nft mint
    uint256 pricePerNft = simpleNFT.PRICE_PER_TOKEN();

    // Testing mint function
    simpleMinter.massMint{value: pricePerNft*numToMint}(numToMint);
    assertEq(numToMint, simpleNFT.balanceOf(address(simpleMinter)), "Unable to mass mint NFTs");

    // Calculating ids of the nfts we minted
    uint256[] memory mintIds = new uint256[](numToMint);
    for (uint256 i; i < numToMint; ++i) {
      mintIds[i] = simpleNFT.tokenOfOwnerByIndex(address(simpleMinter), i);
    }

    // Testing withdraw function to **withdraw all**
    simpleMinter.withdraw(mintIds);
    assertEq(0, simpleNFT.balanceOf(address(simpleMinter)), "Minter contract is still holding NFTs");
    assertEq(numToMint, simpleNFT.balanceOf(minterEoa), "EOA did not receive all NFTs from Minter contract");
  }

  /// @notice Test massMint function when minting is not live
  function testMintNotActiveRevert() public {
    // Enforce that the sale is not active
    if(simpleNFT.saleIsActive()) {
      changePrank(nftOwner);
      simpleNFT.setSaleState(false);
    }
    changePrank(minterEoa);
    // Number of nfts that we will mint
    uint numToMint = 30;
    // Price per nft mint
    uint256 pricePerNft = simpleNFT.PRICE_PER_TOKEN();

    // Test if next function call results in a revert
    vm.expectRevert(bytes("Sale must be active to mint tokens"));

    // Making low level call to catch transaction status (can also be done with normal call)
    bytes memory callData = abi.encodeWithSignature("massMint(uint256)", numToMint);
    (bool status, ) = address(simpleMinter).call{value: pricePerNft*numToMint}(callData);

    assertTrue(status, "expectedRevert: call did not revert");
  }
}
