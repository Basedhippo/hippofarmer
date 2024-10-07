// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./Base64.sol";
import "./IDungToken.sol"; // Interface for DUNG token

/// @title HippoBreeds
/// @notice A contract to mint and breed Legendary Hippo NFTs, with special steroid-boosted Hippos.
/// @dev Inherits from ERC721, ERC721URIStorage, Ownable, and ReentrancyGuard.
contract HippoBreeds is ERC721, ERC721URIStorage, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    // Interface for the $DUNG token
    IDungToken public dungToken;

    struct TraitStruct {
        string name;
        string description;
        uint256 strength; // Strength stat (out of 100)
        uint256 endurance; // Endurance stat (out of 100)
        uint256 speed; // Speed stat (out of 100)
        uint256 juicedLevel; // Steroid level (up to 10)
        string environment; // Habitat of the hippo
        bool breeded; // Indicates if the hippo has been bred
        bool isTrenHippo; // Indicates if the hippo has become a TrenHippo
        uint256[] parents; // IDs of the parents
        string rarity; // Rarity classification (e.g., "Legendary")
        string specialTrait; // Special traits like "Laser Eyes", "Golden Horn", etc.
    }

    struct MintStruct {
        uint256 id;
        address owner;
        uint256 mintCost;
        uint256 timestamp;
        TraitStruct traits;
    }

    string public baseURI;
    uint256 public maxSupply = 888; // Maximum supply of Legendary Hippos
    uint256 public mintCost = 888888888; // Mint cost in SUN (5 TRX)
    uint256 public steroidCost = 699420000; // Steroid cost in SUN (699.42 TRX)
    uint256 public dungRequirement = 100000 * (10 ** 18); // 100,000 $DUNG tokens required to mint

    mapping(uint256 => MintStruct) public minted;
    mapping(uint256 => bool) public tokenIdExist;
    mapping(address => uint256) public steroidBalance;

    string[] environments = ["Savannah", "Mud Bath", "Deep River", "Jungle", "Luxury Hippo Spa"];
    string[] specialTraits = ["Broken Crackpipe", "Laser Eyes", "Golden Horn", "Diamond Skin", "Flaming Mohawk", "Neon Tusk", "Bulletproof Hide"];
    string[] rarities = ["Legendary", "Epic", "Mythical", "Divine"];

    address public devWallet;
    address public stakingPoolWallet;

    event SteroidPurchased(address indexed buyer, uint256 amount);
    event HippoTransformed(uint256 tokenId, string newName);
    event HippoMinted(address indexed owner, uint256 tokenId);
    event HippoBred(address indexed owner, uint256 tokenId);

    /// @notice Initializes the contract with base parameters.
    /// @param _name The name of the NFT collection.
    /// @param _symbol The symbol for the NFT collection.
    /// @param _BaseURI The base URI for metadata.
    /// @param _dungToken Address of the $DUNG token contract.
    /// @param _devWallet Address of the developer wallet.
    /// @param _stakingPoolWallet Address of the staking pool wallet.
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _BaseURI,
        address _dungToken,
        address _devWallet,
        address _stakingPoolWallet
    ) ERC721(_name, _symbol) {
        baseURI = _BaseURI;
        dungToken = IDungToken(_dungToken);
        devWallet = _devWallet;
        stakingPoolWallet = _stakingPoolWallet;
    }

    /// @dev Internal function to return the base URI for the token metadata.
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /// @notice Mints a legendary Hippo NFT, ensuring the user holds 100,000 $DUNG tokens.
    function mintLegendaryHippo() public payable nonReentrant {
        require(_tokenIdCounter.current() < maxSupply, "All legendary hippos have been minted");
        require(msg.value >= mintCost, "Insufficient funds for minting");
        require(dungToken.balanceOf(msg.sender) >= dungRequirement, "You need 100,000 $DUNG to mint a legendary hippo");

        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _performMinting(tokenId);

        TraitStruct memory hippo = generateLegendaryTraits(tokenId);
        minted[tokenId].traits = hippo;
        minted[tokenId].mintCost = msg.value;

        payTo(devWallet, msg.value);

        emit HippoMinted(msg.sender, tokenId);
    }

    /// @notice Allows breeding of two existing NFTs to create a new one.
    function breedNft(uint256 fatherTokenId, uint256 motherTokenId) public payable nonReentrant {
        require(tokenIdExist[fatherTokenId], "Father hippo does not exist");
        require(tokenIdExist[motherTokenId], "Mother hippo does not exist");
        require(_tokenIdCounter.current() < maxSupply, "All hippos have been bred");
        require(msg.value >= mintCost, "Insufficient funds for breeding");

        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _performMinting(tokenId);

        TraitStruct memory hippo = generateBreededTraits(fatherTokenId, motherTokenId);
        minted[tokenId].traits = hippo;

        payTo(devWallet, msg.value);

        emit HippoBred(msg.sender, tokenId);
    }

    /// @notice Purchases a steroid boost for the Hippo NFT.
    function buySteroid() public payable {
        require(msg.value >= steroidCost, "Insufficient funds for Steroid NFT");
        steroidBalance[msg.sender]++;

        uint256 devShare = msg.value / 2;
        uint256 stakingShare = msg.value - devShare;

        payTo(devWallet, devShare);
        payTo(stakingPoolWallet, stakingShare);

        emit SteroidPurchased(msg.sender, 1);
    }

    /// @notice Boosts the juiced level of a Hippo using steroids.
    function boostJuicedLevel(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "Not your hippo");
        require(steroidBalance[msg.sender] > 0, "No steroids available");
        require(minted[tokenId].traits.juicedLevel < 10, "Max juiced level reached");

        minted[tokenId].traits.juicedLevel++;
        steroidBalance[msg.sender]--;

        if (minted[tokenId].traits.juicedLevel == 10) {
            transformToTrenHippo(tokenId);
        }
    }

    /// @dev Internal function to handle Hippo transformation.
    function transformToTrenHippo(uint256 tokenId) internal {
        minted[tokenId].traits.name = string(abi.encodePacked("TRENHIPPO #", tokenId.toString()));
        minted[tokenId].traits.strength += randomNum(20, block.timestamp, 1);
        minted[tokenId].traits.endurance += randomNum(20, block.timestamp, 2);
        minted[tokenId].traits.speed += randomNum(20, block.timestamp, 3);
        minted[tokenId].traits.isTrenHippo = true;

        emit HippoTransformed(tokenId, minted[tokenId].traits.name);
    }

    /// @dev Internal minting function.
    function _performMinting(uint256 tokenId) internal returns (bool) {
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI(tokenId));

        MintStruct memory mint;
        mint.id = tokenId;
        mint.owner = msg.sender;
        mint.timestamp = block.timestamp;
        minted[tokenId] = mint;
        tokenIdExist[tokenId] = true;

        return true;
    }

    /// @dev Returns token URI, building metadata for the NFT.
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return buildMetadata(tokenId);
    }

    /// @dev Builds metadata for an NFT.
    function buildMetadata(uint256 tokenId) internal view returns (string memory) {
        TraitStruct memory traits = minted[tokenId].traits;

        bytes memory attributesJson = buildAttributesJson(
            traits.environment,
            traits.strength,
            traits.endurance,
            traits.speed,
            traits.juicedLevel,
            traits.rarity,
            traits.specialTrait
        );

        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(
                bytes(abi.encodePacked(
                    '{"id":"', tokenId.toString(),
                    '","name":"', traits.name,
                    '","description":"', traits.description,
                    '","attributes":', attributesJson, "}"
                ))
            )
        ));
    }

    /// @dev Builds the attributes JSON for metadata.
    function buildAttributesJson(
        string memory environment,
        uint256 strength,
        uint256 endurance,
        uint256 speed,
        uint256 juicedLevel,
        string memory rarity,
        string memory specialTrait
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(
            '[{"trait_type":"Environment","value":"', environment, '"},',
            '{"trait_type":"Strength","value":"', strength.toString(), '"},',
            '{"trait_type":"Endurance","value":"', endurance.toString(), '"},',
            '{"trait_type":"Speed","value":"', speed.toString(), '"},',
            '{"trait_type":"Juiced Level","value":"', juicedLevel.toString(), '"},',
            '{"trait_type":"Rarity","value":"', rarity, '"},',
            '{"trait_type":"Special Trait","value":"', specialTrait, '"}]'
        );
    }

    /// @dev Utility function to handle payments.
    function payTo(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}("");
        require(success, "Transfer failed.");
    }

    /// @dev Generates random number for traits.
    function randomNum(uint256 modulus, uint256 seed, uint256 salt) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, seed, salt))) % modulus;
    }

    /// @dev Overridden function to support URI storage.
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    /// @dev Overridden function to support interface detection.
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @dev Generate traits for a legendary hippo.
    function generateLegendaryTraits(uint256 tokenId) internal view returns (TraitStruct memory) {
        TraitStruct memory hippo;
        hippo.name = string(abi.encodePacked("Legendary Hippo #", tokenId.toString()));
        hippo.description = "A legendary hippo with unique traits.";
        hippo.strength = randomNum(100, block.timestamp, 1);
        hippo.endurance = randomNum(100, block.timestamp, 2);
        hippo.speed = randomNum(100, block.timestamp, 3);
        hippo.juicedLevel = 0;
        hippo.environment = environments[randomNum(environments.length, block.timestamp, 4)];
        hippo.rarity = rarities[randomNum(rarities.length, block.timestamp, 5)];
        hippo.specialTrait = specialTraits[randomNum(specialTraits.length, block.timestamp, 6)];
        hippo.breeded = false;
        hippo.isTrenHippo = false;
        return hippo;
    }

    /// @dev Generate traits for a bred hippo.
    function generateBreededTraits(uint256 fatherTokenId, uint256 motherTokenId) internal view returns (TraitStruct memory) {
        TraitStruct memory hippo;
        hippo.name = string(abi.encodePacked("Bred Hippo #", _tokenIdCounter.current().toString()));
        hippo.description = "A hippo bred from two legendary parents.";
        hippo.strength = (minted[fatherTokenId].traits.strength + minted[motherTokenId].traits.strength) / 2;
        hippo.endurance = (minted[fatherTokenId].traits.endurance + minted[motherTokenId].traits.endurance) / 2;
        hippo.speed = (minted[fatherTokenId].traits.speed + minted[motherTokenId].traits.speed) / 2;
        hippo.juicedLevel = 0;
        hippo.environment = environments[randomNum(environments.length, block.timestamp, 7)];
        hippo.rarity = rarities[randomNum(rarities.length, block.timestamp, 8)];
        hippo.specialTrait = specialTraits[randomNum(specialTraits.length, block.timestamp, 9)];
        hippo.breeded = true;
        hippo.isTrenHippo = false;
        hippo.parents = new uint256[](2);
        hippo.parents[0] = fatherTokenId;
        hippo.parents[1] = motherTokenId;
        return hippo;
    }
}
