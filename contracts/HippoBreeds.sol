// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/TRC721/TRC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./Base64.sol";
import "./IDungToken.sol"; // Interface for DUNG token

contract HippoBreeds is TRC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    IDungToken public dungToken;

    struct TraitStruct {
        string name;
        string description;
        uint256 strength;
        uint256 endurance;
        uint256 speed;
        uint256 juicedLevel;
        string environment;
        bool breeded;
        bool isTrenHippo;
        uint256[] parents;
        string rarity;
        string specialTrait;
    }

    struct MintStruct {
        uint256 id;
        address owner;
        uint256 mintCost;
        uint256 timestamp;
        TraitStruct traits;
    }

    string private _baseURIextended;
    uint256 public legendaryMaxSupply = 888;
    uint256 public poodengMaxSupply = 8888;
    uint256 public legendaryMintCost = 888888888;
    uint256 public poodengMintCost = 444444444;
    uint256 public initialSteroidCost = 699420000;
    uint256 public steroidSupply = 100000;
    uint256 public legendaryDungRequirement = 100000 * (10 ** 18);
    uint256 public poodengDungRequirement = 10000 * (10 ** 18);
    uint256 public breedingDungCost = 500 * (10 ** 18);

    mapping(uint256 => MintStruct) public minted;
    mapping(uint256 => bool) public tokenIdExist;
    mapping(address => uint256) public steroidBalance;
    mapping(uint256 => string) private _tokenURIs;

    string[] environments = [
        "Savannah", "Mud Bath", "Deep River", "Jungle", "Luxury Hippo Spa", "Urban Sewer", "Haunted Marsh", "Wasteland", "Abandoned Carnival", "Crypto Swamp"
    ];
    string[] legendaryTraits = [
        "Laser Eyes", "Golden Horn", "Diamond Skin", "Flaming Mohawk", "Neon Tusk", "Bulletproof Hide",
        "Rabid Bite", "Chainsaw Tail", "Radioactive Glow", "Molotov Breath", "Cybernetic Limbs", "Roid Rage",
        "Vitalik Vision", "Elon's Laugh", "Kamala Breath", "Iron Guts", "Phoenix Flame", "Shadow Step",
        "Tsunami Roar", "Quantum Leap", "Galactic Stomp", "Neural Network", "Platinum Mane", "Doom Fists",
        "Cosmic Dust", "Starborn", "Void Walker", "Ancient Wisdom", "Golden Aura", "Chaos Cloak"
    ];
    string[] poodengTraits = [
        "Broken Crackpipe", "Trash Can Armor", "Cursed Tattoo", "Moodeng Cheeks", "Degen Spirit", "Hodl Horn",
        "Blockchain Bloat", "Cryptoholic Frenzy", "Paper Hand Shield", "Diamond Paws", "Cheeky Grin",
        "Rug Pull Escape", "Shill Shout", "Dusty Mane", "Flash Dump", "Pump Roar", "Soft Cap Swing",
        "Market Crash Camouflage", "Whale Tail", "Gas Fee Saver", "Token Trample", "Decentralized Dance",
        "Lambo Dreams", "Crypto Moon Howl", "Staking Stamina", "Whitepaper Wizardry", "Bear Market Brawl",
        "Bull Run Boost", "Airdrop Absorption", "Defi Defender"
    ];
    string[] commonTraits = [
        "Lazy Smile", "Muddy Paws", "Friendly Waddle", "Grumpy Grunt", "Clumsy Tumble", "Water Splash", "Grass Eater",
        "Hippo Yawn", "Snorty Laugh", "Mud Wrestler", "Leaf Muncher", "Sleepy Head", "River Dancer", "Sunbather",
        "Pebble Collector", "Tail Flicker", "Puddle Plopper", "Bug Chaser", "Flower Sniffer", "Shade Seeker",
        "Swamp Tromp", "Berry Picker", "Riverside Roller", "Weed Waddler", "Splash Charger", "Snooze Button",
        "Playful Nibble", "Belly Flop", "Hippo Hiccup", "Gravel Grinder"
    ];
    string[] rarities = ["Legendary", "Epic", "Mythical", "Divine", "Common", "Trash-tier"];

    address public devWallet;
    address public stakingPoolWallet;

    event SteroidPurchased(address indexed buyer, uint256 amount);
    event HippoTransformed(uint256 tokenId, string newName);
    event HippoMinted(address indexed owner, uint256 tokenId);
    event HippoBred(address indexed owner, uint256 tokenId);

    constructor(
        string memory _collectionName,
        string memory _collectionSymbol,
        string memory _BaseURI,
        address _dungToken,
        address _devWallet,
        address _stakingPoolWallet
    ) TRC721(_collectionName, _collectionSymbol) {
        _baseURIextended = _BaseURI;
        dungToken = IDungToken(_dungToken);
        devWallet = _devWallet;
        stakingPoolWallet = _stakingPoolWallet;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        return bytes(base).length > 0 ? string(abi.encodePacked(base, _tokenURI)) : "";
    }

    function mintLegendaryHippo() public payable nonReentrant {
        require(_tokenIdCounter.current() < legendaryMaxSupply, "All legendary hippos have been minted");
        require(msg.value >= legendaryMintCost, "Insufficient funds for minting");
        require(dungToken.balanceOf(msg.sender) >= legendaryDungRequirement, "You need 100,000 $DUNG to mint a legendary hippo");

        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _performMinting(tokenId);

        TraitStruct memory hippo = generateLegendaryTraits(tokenId);
        minted[tokenId].traits = hippo;
        minted[tokenId].mintCost = msg.value;

        payTo(devWallet, msg.value);

        emit HippoMinted(msg.sender, tokenId);
    }

    function mintPoodengHippo() public payable nonReentrant {
        require(_tokenIdCounter.current() < legendaryMaxSupply + poodengMaxSupply, "All Poodeng hippos have been minted");
        require(msg.value >= poodengMintCost, "Insufficient funds for minting");
        require(dungToken.balanceOf(msg.sender) >= poodengDungRequirement, "You need 10,000 $DUNG to mint a Poodeng hippo");

        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _performMinting(tokenId);

        TraitStruct memory hippo = generatePoodengTraits(tokenId);
        minted[tokenId].traits = hippo;
        minted[tokenId].mintCost = msg.value;

        payTo(devWallet, msg.value);

        emit HippoMinted(msg.sender, tokenId);
    }

    function breedNft(uint256 fatherTokenId, uint256 motherTokenId) public payable nonReentrant {
        require(tokenIdExist[fatherTokenId], "Father hippo does not exist");
        require(tokenIdExist[motherTokenId], "Mother hippo does not exist");
        require(msg.value >= legendaryMintCost, "Insufficient funds for breeding");
        require(dungToken.balanceOf(msg.sender) >= breedingDungCost, "You need 500 $DUNG to breed a new hippo");

        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _performMinting(tokenId);

        TraitStruct memory hippo = generateBreededTraits(fatherTokenId, motherTokenId);
        minted[tokenId].traits = hippo;

        dungToken.burnFrom(msg.sender, breedingDungCost / 2);
        dungToken.transferFrom(msg.sender, stakingPoolWallet, breedingDungCost / 2);

        payTo(devWallet, msg.value);

        emit HippoBred(msg.sender, tokenId);
    }

    function buySteroid() public payable {
        require(steroidSupply > 0, "No more steroids available");
        uint256 currentSteroidCost = getCurrentSteroidCost();
        require(msg.value >= currentSteroidCost, "Insufficient funds for Steroid NFT");

        steroidBalance[msg.sender]++;
        steroidSupply--;

        uint256 devShare = msg.value / 2;
        uint256 stakingShare = msg.value - devShare;

        payTo(devWallet, devShare);
        payTo(stakingPoolWallet, stakingShare);

        emit SteroidPurchased(msg.sender, 1);
    }

    function getCurrentSteroidCost() public view returns (uint256) {
        uint256 multiplier = 1 + (200 * (100000 - steroidSupply)) / 100000;
        return initialSteroidCost * multiplier / 10;
    }

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

    function transformToTrenHippo(uint256 tokenId) internal {
        minted[tokenId].traits.name = string(abi.encodePacked("TRENHIPPO #", tokenId.toString()));
        uint256 timestamp = block.timestamp;
        minted[tokenId].traits.strength += randomNum(20, timestamp, 1);
        minted[tokenId].traits.endurance += randomNum(20, timestamp, 2);
        minted[tokenId].traits.speed += randomNum(20, timestamp, 3);
        minted[tokenId].traits.isTrenHippo = true;

        emit HippoTransformed(tokenId, minted[tokenId].traits.name);
    }

    function _performMinting(uint256 tokenId) internal {
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked(tokenId.toString(), ".json")));

        MintStruct memory mint;
        mint.id = tokenId;
        mint.owner = msg.sender;
        mint.timestamp = block.timestamp;
        minted[tokenId] = mint;
        tokenIdExist[tokenId] = true;
    }

    function payTo(address to, uint256 amount) internal {
        (bool success, ) = payable(to).call{value: amount}("");
        require(success, "Transfer failed.");
    }

    function randomNum(uint256 modulus, uint256 seed, uint256 salt) internal view returns (uint256) {
        uint256 timestamp = block.timestamp;
        return uint256(keccak256(abi.encodePacked(timestamp, msg.sender, seed, salt))) % modulus;
    }

    function generateLegendaryTraits(uint256 tokenId) internal view returns (TraitStruct memory) {
        uint256 timestamp = block.timestamp;
        TraitStruct memory hippo;
        hippo.name = string(abi.encodePacked("Legendary Hippo #", tokenId.toString()));
        hippo.description = "A legendary hippo with unique traits.";
        hippo.strength = randomNum(100, timestamp, 1);
        hippo.endurance = randomNum(100, timestamp, 2);
        hippo.speed = randomNum(100, timestamp, 3);
        hippo.juicedLevel = 0;
        hippo.environment = environments[randomNum(environments.length, timestamp, 4)];
        hippo.rarity = rarities[randomNum(4, timestamp, 5)];
        hippo.specialTrait = legendaryTraits[randomNum(legendaryTraits.length, timestamp, 6)];
        hippo.breeded = false;
        hippo.isTrenHippo = false;
        return hippo;
    }

    function generatePoodengTraits(uint256 tokenId) internal view returns (TraitStruct memory) {
        uint256 timestamp = block.timestamp;
        TraitStruct memory hippo;
        hippo.name = string(abi.encodePacked("Poodeng Hippo #", tokenId.toString()));
        hippo.description = "A Poodeng hippo with unique but slightly diluted traits.";
        hippo.strength = randomNum(80, timestamp, 1);
        hippo.endurance = randomNum(80, timestamp, 2);
        hippo.speed = randomNum(80, timestamp, 3);
        hippo.juicedLevel = 0;
        hippo.environment = environments[randomNum(environments.length, timestamp, 4)];
        hippo.rarity = rarities[randomNum(4, timestamp, 5)];
        hippo.specialTrait = poodengTraits[randomNum(poodengTraits.length, timestamp, 6)];
        hippo.breeded = false;
        hippo.isTrenHippo = false;
        return hippo;
    }

    function generateBreededTraits(uint256 fatherTokenId, uint256 motherTokenId) internal view returns (TraitStruct memory) {
        uint256 timestamp = block.timestamp;
        TraitStruct memory hippo;
        hippo.name = string(abi.encodePacked("Bred Hippo #", _tokenIdCounter.current().toString()));
        hippo.description = "A hippo bred from two legendary parents.";
        hippo.strength = (minted[fatherTokenId].traits.strength + minted[motherTokenId].traits.strength) / 2;
        hippo.endurance = (minted[fatherTokenId].traits.endurance + minted[motherTokenId].traits.endurance) / 2;
        hippo.speed = (minted[fatherTokenId].traits.speed + minted[motherTokenId].traits.speed) / 2;
        hippo.juicedLevel = 0;
        hippo.environment = environments[randomNum(environments.length, timestamp, 7)];
        hippo.rarity = rarities[randomNum(rarities.length, timestamp, 8)];

        if (randomNum(10, timestamp, 9) > 5) {
            hippo.specialTrait = legendaryTraits[randomNum(legendaryTraits.length, timestamp, 10)];
        } else if (randomNum(10, timestamp, 11) > 5) {
            hippo.specialTrait = poodengTraits[randomNum(poodengTraits.length, timestamp, 12)];
        } else {
            hippo.specialTrait = commonTraits[randomNum(commonTraits.length, timestamp, 13)];
        }

        hippo.breeded = true;
        hippo.isTrenHippo = false;
        hippo.parents = new uint256[](2);
        hippo.parents[0] = fatherTokenId;
        hippo.parents[1] = motherTokenId;
        return hippo;
    }
}
