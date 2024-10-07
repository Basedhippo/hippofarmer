const { expect } = require("chai");
const { ethers, waffle } = require("hardhat");

describe("HippoBreeds Contract", function () {
  let HippoBreeds;
  let hippoBreeds;
  let owner;
  let user1;
  let user2;

  // Set up the contract and variables before each test case
  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();

    // Define contract parameters
    const _name = "Legendary Hippo";
    const _symbol = "HIPPO";
    const _baseUri = "ipfs://baseURI/";
    const _maxSupply = 888;

    // Deploy the HippoBreeds contract
    HippoBreeds = await ethers.getContractFactory("HippoBreeds");
    hippoBreeds = await HippoBreeds.deploy(_name, _symbol, _baseUri, _maxSupply);
    await hippoBreeds.deployed();
  });

  it("Should deploy the contract with the correct name, symbol, and baseURI", async function () {
    expect(await hippoBreeds.name()).to.equal("Legendary Hippo");
    expect(await hippoBreeds.symbol()).to.equal("HIPPO");
    expect(await hippoBreeds._baseURI()).to.equal("ipfs://baseURI/");
  });

  it("Should mint an NFT successfully", async function () {
    const mintCost = await hippoBreeds.mintCost();

    // User1 mints an NFT
    await hippoBreeds.connect(user1).mintNft({ value: mintCost });

    // Check if the token was minted correctly
    const mintedNft = await hippoBreeds.getNft(1);
    expect(mintedNft.id).to.equal(1);
    expect(mintedNft.owner).to.equal(user1.address);
  });

  it("Should fail to mint NFT with insufficient funds", async function () {
    const insufficientAmount = ethers.utils.parseEther("0.002");

    await expect(hippoBreeds.connect(user1).mintNft({ value: insufficientAmount }))
      .to.be.revertedWith("Insufficient fund for minting");
  });

  it("Should mint multiple NFTs and count them correctly", async function () {
    const mintCost = await hippoBreeds.mintCost();

    // Mint first NFT by user1
    await hippoBreeds.connect(user1).mintNft({ value: mintCost });
    expect(await hippoBreeds.getAllNfts()).to.have.lengthOf(1);

    // Mint second NFT by user2
    await hippoBreeds.connect(user2).mintNft({ value: mintCost });
    expect(await hippoBreeds.getAllNfts()).to.have.lengthOf(2);
  });

  it("Should breed two NFTs and generate a new NFT with inherited traits", async function () {
    const mintCost = await hippoBreeds.mintCost();

    // Mint two NFTs by different users
    await hippoBreeds.connect(user1).mintNft({ value: mintCost });
    await hippoBreeds.connect(user2).mintNft({ value: mintCost });

    // Get the two parent NFTs
    const parent1 = await hippoBreeds.getNft(1);
    const parent2 = await hippoBreeds.getNft(2);

    // Breed the two NFTs
    await hippoBreeds.connect(user1).breedNft(1, 2, { value: mintCost });

    // Check if the new NFT is correctly bred
    const bredNft = await hippoBreeds.getNft(3);
    expect(bredNft.id).to.equal(3);
    expect(bredNft.owner).to.equal(user1.address);
    expect(bredNft.traits.parents[0]).to.equal(1);
    expect(bredNft.traits.parents[1]).to.equal(2);

    // Check that the traits are correctly inherited
    expect(bredNft.traits.environment).to.equal(parent1.traits.environment);  // Inherited from parent1
    expect(bredNft.traits.weapon).to.equal(parent2.traits.weapon);            // Inherited from parent2
  });

  it("Should fail to breed if one or both parent tokens do not exist", async function () {
    const mintCost = await hippoBreeds.mintCost();

    // Attempt to breed without having enough tokens
    await expect(hippoBreeds.connect(user1).breedNft(1, 999, { value: mintCost }))
      .to.be.revertedWith("Father does not exist");

    await expect(hippoBreeds.connect(user1).breedNft(999, 1, { value: mintCost }))
      .to.be.revertedWith("Mother does not exist");
  });

  it("Should fail to breed with insufficient funds", async function () {
    const mintCost = await hippoBreeds.mintCost();

    // Mint two NFTs
    await hippoBreeds.connect(user1).mintNft({ value: mintCost });
    await hippoBreeds.connect(user2).mintNft({ value: mintCost });

    // Attempt to breed with insufficient funds
    const insufficientAmount = ethers.utils.parseEther("0.002");
    await expect(hippoBreeds.connect(user1).breedNft(1, 2, { value: insufficientAmount }))
      .to.be.revertedWith("Insufficient fund for minting");
  });

  it("Should allow the owner to set a new base URI", async function () {
    await hippoBreeds.connect(owner).setBaseURI("ipfs://newBaseUri/");
    expect(await hippoBreeds._baseURI()).to.equal("ipfs://newBaseUri/");
  });

  it("Should fail to set base URI if not owner", async function () {
    await expect(hippoBreeds.connect(user1).setBaseURI("ipfs://newBaseUri/"))
      .to.be.revertedWith("Ownable: caller is not the owner");
  });
});
