const { assert, expect } = require('chai');

contract('HippoBreeds', (accounts) => {
  let HippoBreeds;
  let dungToken;
  const [deployer, user1, user2] = accounts;
  const mintCost = web3.utils.toWei('0.005', 'ether');
  const steroidCost = web3.utils.toWei('699.420', 'trx');
  const DUNG_REQUIRED = web3.utils.toWei('100000', 'ether');

  before(async () => {
    // Deploy the mock DUNG token and the HippoBreeds contract
    dungToken = await artifacts.require('IDungToken').new();
    HippoBreeds = await artifacts.require('HippoBreeds').new(
      'Legendary Hippo', 
      'HIPPO', 
      'ipfs://baseURI/', 
      dungToken.address
    );

    // Distribute DUNG tokens to users
    await dungToken.mint(user1, DUNG_REQUIRED);
    await dungToken.mint(user2, DUNG_REQUIRED);
  });

  it('should deploy the contract with the correct name, symbol, and base URI', async () => {
    const name = await HippoBreeds.name();
    const symbol = await HippoBreeds.symbol();
    const baseURI = await HippoBreeds._baseURI();

    assert.equal(name, 'Legendary Hippo');
    assert.equal(symbol, 'HIPPO');
    assert.equal(baseURI, 'ipfs://baseURI/');
  });

  it('should mint a legendary hippo with the correct $DUNG requirement', async () => {
    // Approve the DUNG token for the minting user
    await dungToken.approve(HippoBreeds.address, DUNG_REQUIRED, { from: user1 });

    // User 1 mints a legendary hippo
    const result = await HippoBreeds.mintLegendaryHippo({ from: user1, value: mintCost });

    // Check if the token was minted correctly
    const mintedNft = await HippoBreeds.getNft(1);
    assert.equal(mintedNft.id, 1);
    assert.equal(mintedNft.owner, user1);
    assert.equal(mintedNft.traits.rarity, 'Legendary');
    assert.isTrue(mintedNft.traits.specialTrait.length > 0); // Special trait should be non-empty
  });

  it('should fail to mint without owning 100,000 $DUNG', async () => {
    const mintCost = web3.utils.toWei('0.005', 'ether');
    await dungToken.burn(user2, DUNG_REQUIRED, { from: user2 }); // Burn user2's DUNG tokens

    await expect(
      HippoBreeds.mintLegendaryHippo({ from: user2, value: mintCost })
    ).to.be.rejectedWith('You need 100,000 $DUNG to mint a legendary hippo');
  });

  it('should buy steroids and increase juiced level', async () => {
    // User 1 buys steroids
    await HippoBreeds.buySteroid({ from: user1, value: steroidCost });
    const steroidBalance = await HippoBreeds.steroidBalance(user1);

    assert.equal(steroidBalance.toNumber(), 1);

    // Boost juiced level of Hippo #1
    await HippoBreeds.boostJuicedLevel(1, { from: user1 });
    const boostedNft = await HippoBreeds.getNft(1);

    assert.equal(boostedNft.traits.juicedLevel, 1);
  });

  it('should transform into a TrenHippo after reaching max juiced level', async () => {
    // User 1 buys enough steroids to max out Hippo #1's juiced level
    for (let i = 0; i < 9; i++) {
      await HippoBreeds.buySteroid({ from: user1, value: steroidCost });
      await HippoBreeds.boostJuicedLevel(1, { from: user1 });
    }

    const transformedNft = await HippoBreeds.getNft(1);
    assert.equal(transformedNft.traits.juicedLevel, 10);
    assert.isTrue(transformedNft.traits.isTrenHippo);
    assert.include(transformedNft.traits.name, 'TRENHIPPO');
  });

  it('should breed two NFTs and generate a new NFT with inherited traits', async () => {
    // Mint a second legendary hippo for breeding
    await dungToken.approve(HippoBreeds.address, DUNG_REQUIRED, { from: user2 });
    await HippoBreeds.mintLegendaryHippo({ from: user2, value: mintCost });

    // Breed Hippo #1 and Hippo #2
    await HippoBreeds.breedNft(1, 2, { from: user1, value: mintCost });

    // Check if the new NFT was bred successfully
    const bredNft = await HippoBreeds.getNft(3);
    assert.equal(bredNft.id, 3);
    assert.equal(bredNft.owner, user1);
    assert.equal(bredNft.traits.parents[0], 1);
    assert.equal(bredNft.traits.parents[1], 2);

    // Check the inherited traits
    const parent1 = await HippoBreeds.getNft(1);
    const parent2 = await HippoBreeds.getNft(2);
    assert.equal(bredNft.traits.strength, Math.floor((parent1.traits.strength + parent2.traits.strength) / 2));
  });

  it('should fail to breed without enough funds', async () => {
    const insufficientAmount = web3.utils.toWei('0.002', 'ether');

    await expect(
      HippoBreeds.breedNft(1, 2, { from: user1, value: insufficientAmount })
    ).to.be.rejectedWith('Insufficient funds for breeding');
  });

  it('should allow the owner to set a new base URI', async () => {
    await HippoBreeds.setBaseURI('ipfs://newBaseUri/', { from: deployer });
    const baseURI = await HippoBreeds._baseURI();

    assert.equal(baseURI, 'ipfs://newBaseUri/');
  });

  it('should fail to set base URI if not owner', async () => {
    await expect(HippoBreeds.setBaseURI('ipfs://newBaseUri/', { from: user1 })).to.be.rejectedWith('Ownable: caller is not the owner');
  });
});
