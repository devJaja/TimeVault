// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VaultNFT is ERC721, Ownable {
    struct VaultMetadata {
        string name;
        uint256 balance;
        uint256 goalAmount;
        uint256 unlockTime;
        string tier;
    }
    
    mapping(uint256 => VaultMetadata) public vaultMetadata;
    uint256 public nextTokenId;
    
    constructor() ERC721("TimeVault NFT", "TVNFT") Ownable(msg.sender) {}
    
    function mint(
        address to,
        string memory vaultName,
        uint256 balance,
        uint256 goalAmount,
        uint256 unlockTime
    ) external onlyOwner returns (uint256) {
        uint256 tokenId = nextTokenId++;
        
        string memory tier = _calculateTier(balance);
        
        vaultMetadata[tokenId] = VaultMetadata({
            name: vaultName,
            balance: balance,
            goalAmount: goalAmount,
            unlockTime: unlockTime,
            tier: tier
        });
        
        _mint(to, tokenId);
        return tokenId;
    }
    
    function updateBalance(uint256 tokenId, uint256 newBalance) external onlyOwner {
        require(_exists(tokenId), "Token does not exist");
        vaultMetadata[tokenId].balance = newBalance;
        vaultMetadata[tokenId].tier = _calculateTier(newBalance);
    }
    
    function _calculateTier(uint256 balance) internal pure returns (string memory) {
        if (balance >= 10 ether) return "Platinum";
        if (balance >= 5 ether) return "Gold";
        if (balance >= 1 ether) return "Silver";
        return "Bronze";
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        
        VaultMetadata memory metadata = vaultMetadata[tokenId];
        
        return string(abi.encodePacked(
            "data:application/json;base64,",
            _encode(abi.encodePacked(
                '{"name":"', metadata.name, '",',
                '"description":"TimeVault NFT Receipt",',
                '"attributes":[',
                '{"trait_type":"Balance","value":"', _toString(metadata.balance), '"},',
                '{"trait_type":"Goal","value":"', _toString(metadata.goalAmount), '"},',
                '{"trait_type":"Tier","value":"', metadata.tier, '"}',
                ']}'
            ))
        ));
    }
    
    function _encode(bytes memory data) internal pure returns (string memory) {
        // Simple base64 encoding placeholder
        return "encoded_data";
    }
    
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        
        return string(buffer);
    }
}
