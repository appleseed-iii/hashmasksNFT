// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "solmate/tokens/ERC721.sol";

contract Masks is ERC721 {
    uint256 public constant MAX_NFT_SUPPLY = 25; // was 16384 IRL
    string public baseURI;
    uint public totalSupply;

    constructor() ERC721("Hashmasks", "MASK") {
        baseURI = "whatever/";
    }

    /**
    * @dev Mints Masks
    */
    function mintNFT(uint256 numberOfNfts) public payable {
        require(totalSupply < MAX_NFT_SUPPLY, "Sale has already ended");
        require(numberOfNfts > 0, "numberOfNfts cannot be 0");
        require(numberOfNfts <= 20, "You may not buy more than 20 NFTs at once");
        require(totalSupply + numberOfNfts <= MAX_NFT_SUPPLY, "Exceeds MAX_NFT_SUPPLY");
        require(getNFTPrice() * numberOfNfts == msg.value, "Ether value sent is not correct");

        // once the re-entered execution completes, the loop containing _safeMint execution...
        // continues to be processed without a conditional check on totalSupply.
        for (uint i = 0; i < numberOfNfts; i++) {
            uint256 mintIndex = ++totalSupply;
            _safeMint(msg.sender, mintIndex);
        }
    }

    /**
    * @dev Add function to demonstrate the mitigation
    */
    function fixedMint(uint256 numberOfNfts) public payable {
        require(totalSupply < MAX_NFT_SUPPLY, "Sale has already ended");
        require(numberOfNfts > 0, "numberOfNfts cannot be 0");
        require(numberOfNfts <= 20, "You may not buy more than 20 NFTs at once");
        require(totalSupply + numberOfNfts <= MAX_NFT_SUPPLY, "Exceeds MAX_NFT_SUPPLY");
        require(getNFTPrice() * numberOfNfts == msg.value, "Ether value sent is not correct");

        // once the re-entered execution completes, the loop containing _safeMint execution...
        // continues to be processed without a conditional check on totalSupply.
        for (uint i = 0; i < numberOfNfts; i++) {
            uint256 mintIndex = ++totalSupply;
            require(totalSupply < MAX_NFT_SUPPLY, "Sale has already ended");
            _safeMint(msg.sender, mintIndex);
        }
    }

    /**
     * @dev Gets current Hashmask Price
     */
    function getNFTPrice() public view returns (uint256) {
        // they had a complex pricing function... we simplify it here
        return 0.1 ether;
    }

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        return "";
    }

}
