// SPDX-Licenje-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console.sol";
import "../src/CappedMinter.sol";
import "../src/CappedHelper.sol";
import "../src/mocks/CappedNFT.sol";
import "../src/IMintableERC721.sol";

/// @title Test Simple Minter contract
/// @author 0xMouseLess
contract CappedMinterTest is Test {

  /// @dev The nft we are minting
  CappedNFT cappedNFT;

  /// @dev Mass minter contract
  CappedMinter cappedMinter;

  /// @dev Mock EOA
  address minterEoa = 0xc0FFee0000000000000000000000000000000000;
  /// @dev NFT Contract Owner
  address nftOwner = 0x00000000003b3cc22aF3aE1EAc0440BcEe416B40;

  /// @dev NFT mint price
  uint128 immutable PRICE_PER_NFT = 0.05 ether;

  /// @dev Max mints per call 
  uint256 immutable MAX_MINT_PER_ADDRESS = 5;

  /// @notice Setup tests
  function setUp() public {
    // Deploy mock nft contract from mock owner
    vm.prank(nftOwner);
    cappedNFT = new CappedNFT();
    // Setup all calls to happen from mock eoa
    startHoax(minterEoa, 100 ether);
    // Setup minting contract
    cappedMinter = new CappedMinter(address(cappedNFT));
  }

  /// @notice Test massMint function when minting is not live
  function testMintNotActiveRevert() public {
    // Enforce that the sale is active
    if(cappedNFT.saleIsActive()) {
      changePrank(nftOwner);
      cappedNFT.setSaleState(false);
    }
    changePrank(minterEoa);

    uint helperInstances = 10;
    uint totalMinted = helperInstances * MAX_MINT_PER_ADDRESS;

    // Test if next function call results in a revert
    vm.expectRevert(bytes("Sale must be active to mint tokens"));
    cappedMinter.massMint{value: totalMinted*PRICE_PER_NFT}(helperInstances);
  }

  /// @notice Test main massMint function when minting is live
  function testMintActive() public {
    // Enforce that the sale is active
    if(!cappedNFT.saleIsActive()) {
      changePrank(nftOwner);
      cappedNFT.setSaleState(true);
    }
    changePrank(minterEoa);

    uint helperInstances = 10;
    uint totalMinted = helperInstances * MAX_MINT_PER_ADDRESS;

    // Testing mint function
    cappedMinter.massMint{value: totalMinted*PRICE_PER_NFT}(helperInstances);
    assertEq(totalMinted, cappedNFT.balanceOf(address(cappedMinter)), "Unable to mass mint NFTs");

    // Calculating ids of the nfts we minted
    uint256[] memory mintIds = new uint256[](totalMinted);
    for (uint256 i; i < totalMinted; ++i) {
      mintIds[i] = cappedNFT.tokenOfOwnerByIndex(address(cappedMinter), i);
    }

    // Testing withdraw function to **withdraw all**
    cappedMinter.withdraw(mintIds);
    assertEq(0, cappedNFT.balanceOf(address(cappedMinter)), "Minter contract is still holding NFTs");
    assertEq(totalMinted, cappedNFT.balanceOf(minterEoa), "EOA did not receive all NFTs from Minter contract");
  }

  ////////////////////////
  /// HELPER FUNCTIONS ///
  ////////////////////////

  /// @notice Test minting more than account limit
  function testHelperExceedMintLimitRevert() public {
    // Enforce that the sale is active
    if(!cappedNFT.saleIsActive()) {
      changePrank(nftOwner);
      cappedNFT.setSaleState(true);
    }
    changePrank(minterEoa);
    
    // Mint from our EOA for this test
    cappedNFT.mint{value: PRICE_PER_NFT*MAX_MINT_PER_ADDRESS}(MAX_MINT_PER_ADDRESS);

    // Expect a revert as we are minting from the same addr twice
    vm.expectRevert(bytes("Exceeded account mint limit"));
    cappedNFT.mint{value: PRICE_PER_NFT*MAX_MINT_PER_ADDRESS}(MAX_MINT_PER_ADDRESS);
  }

  /// @notice Test to check if the helper contract is able to mint
  function testHelperMintingActive() public {
    // Enforce that the sale is active
    if(!cappedNFT.saleIsActive()) {
      changePrank(nftOwner);
      cappedNFT.setSaleState(true);
    }
    changePrank(minterEoa);
    CappedHelper cappedHelper = new CappedHelper{value: PRICE_PER_NFT*MAX_MINT_PER_ADDRESS}(IMintableERC721(address(cappedNFT)));
    assertEq(MAX_MINT_PER_ADDRESS, cappedNFT.balanceOf(minterEoa), "msg.sender did not receive all nfts from minter contract");
    assertEq(0, cappedNFT.balanceOf(address(cappedHelper)), "minter contract still holds some nfts");
  }

  /// @notice Test when minting is not live
  function testHelperMintingNotActiveRevert() public {
    // Enforce that the sale is not active
    if(cappedNFT.saleIsActive()) {
      changePrank(nftOwner);
      cappedNFT.setSaleState(false);
    }
    changePrank(minterEoa);

    // Test if next function call results in a revert
    vm.expectRevert(bytes("Sale must be active to mint tokens"));
    new CappedHelper{value: PRICE_PER_NFT*MAX_MINT_PER_ADDRESS}(IMintableERC721(address(cappedNFT)));
  }
}
