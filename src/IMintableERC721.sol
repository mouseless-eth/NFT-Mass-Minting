// @title Interface based on our target contract 
interface IMintableERC721 {
    function mint(uint numberOfTokens) external payable;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}
