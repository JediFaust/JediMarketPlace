/* eslint-disable no-unused-vars */
/* eslint-disable no-unused-expressions */
import { expect } from "chai";
import { Contract } from "ethers";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";

describe("JediMarketPlace", function () {
  let owner: SignerWithAddress;
  let userOne: SignerWithAddress;
  let userTwo: SignerWithAddress;
  let userThree: SignerWithAddress;
  let jediMarket: Contract;
  let jedi20: Contract;
  let jedi721: Contract;
  let jedi1155: Contract;

  beforeEach(async function () {
    // Get the signers
    [owner, userOne, userTwo, userThree] = await ethers.getSigners();

    // Deploy the JDT token
    const testERC20 = await ethers.getContractFactory("Jedi20");
    jedi20 = <Contract>await testERC20.deploy("JDT", "JediToken", 10000000, 1);
    await jedi20.deployed();

    // Deploy the JNFT721 token
    const testERC721 = await ethers.getContractFactory("Jedi721");
    jedi721 = <Contract>await testERC721.deploy();
    await jedi721.deployed();

    // Deploy the JNFT1155 token
    const testERC1155 = await ethers.getContractFactory("Jedi1155");
    jedi1155 = <Contract>await testERC1155.deploy();
    await jedi1155.deployed();

    // Deploy the JediMarketPlace
    const testMarketPlace = await ethers.getContractFactory("JediMarketPlace");
    jediMarket = <Contract>(
      await testMarketPlace.deploy(
        jedi20.address,
        jedi721.address,
        jedi1155.address
      )
    );
    await jediMarket.deployed();

    // Set MarketPlace as minter
    await jedi721.setMinter(jediMarket.address);
    await jedi1155.setMinter(jediMarket.address);
  });

  it("should be able to mint and get totalSupply on Jedi1155", async function () {
    await jediMarket.connect(userOne).createItem1155(100);
    const firstSupply = await jedi1155.totalSupply();
    const firstTokenSupply = await jedi1155.tokenSupply(0);

    await jediMarket.connect(userTwo).createItem1155(1);
    const secondSupply = await jedi1155.totalSupply();
    const secondTokenSupply = await jedi1155.tokenSupply(1);

    expect(firstSupply).to.eq(1);
    expect(firstTokenSupply).to.eq(100);
    expect(secondSupply).to.eq(2);
    expect(secondTokenSupply).to.eq(1);
  });

  it("should be able to list and buy on Jedi1155", async function () {
    await jediMarket.connect(userOne).createItem1155(100);

    await jedi1155.connect(userOne).setApprovalForAll(jediMarket.address, true);
    await jediMarket.connect(userOne).listItem1155(0, 100, 1000);

    await jedi20.mint(userTwo.address, 1000);
    await jedi20.connect(userTwo).approve(jediMarket.address, 1000);
    await jediMarket.connect(userTwo).buyItem1155(0);

    expect(await jedi1155.balanceOf(userTwo.address, 0)).to.eq(100);
  });

  it("should be able to list and cancel on Jedi1155", async function () {
    await jediMarket.connect(userOne).createItem1155(100);

    expect(await jedi1155.balanceOf(userOne.address, 0)).to.eq(100);

    await jedi1155.connect(userOne).setApprovalForAll(jediMarket.address, true);
    await jediMarket.connect(userOne).listItem1155(0, 100, 1000);

    expect(await jedi1155.balanceOf(userOne.address, 0)).to.eq(0);

    await jediMarket.connect(userOne).cancel1155(0);

    expect(await jedi1155.balanceOf(userOne.address, 0)).to.eq(100);
  });

  it("should be able to list on auction and cancel on Jedi1155", async function () {
    await jediMarket.connect(userOne).createItem1155(100 * (10 ^ 18));

    await jedi1155.connect(userOne).setApprovalForAll(jediMarket.address, true);
    await jediMarket
      .connect(userOne)
      .listItemOnAuction1155(0, 100 * (10 ^ 18), 100000);

    expect(await jedi1155.balanceOf(userOne.address, 0)).to.eq(0);

    await jedi20.mint(userOne.address, 110000);
    await jedi20.connect(userOne).approve(jediMarket.address, 110000);
    await jediMarket.connect(userOne).makeBid1155(0, 110000);

    expect(await jedi20.balanceOf(userOne.address)).to.eq(0);
    expect(await jedi20.balanceOf(jediMarket.address)).to.eq(110000);

    await jedi20.mint(userTwo.address, 150000);
    await jedi20.connect(userTwo).approve(jediMarket.address, 150000);
    await jediMarket.connect(userTwo).makeBid1155(0, 150000);

    expect(await jedi20.balanceOf(userTwo.address)).to.eq(0);
    expect(await jedi20.balanceOf(userOne.address)).to.eq(110000);
    expect(await jedi20.balanceOf(jediMarket.address)).to.eq(150000);

    await jediMarket.backDate1155(0);

    expect(jediMarket.connect(userOne).finishAuction1155(0)).to.be.revertedWith(
      "Bids less than 2"
    );

    await jediMarket.connect(userOne).cancelAuction1155(0);

    expect(await jedi20.balanceOf(userTwo.address)).to.eq(150000);
    expect(await jedi1155.balanceOf(userOne.address, 0)).to.eq(100 * (10 ^ 18));
  });

  it("should be able to list and not finish early", async function () {
    await jediMarket.connect(userOne).createItem1155(100);

    await jedi1155.connect(userOne).setApprovalForAll(jediMarket.address, true);
    await jediMarket.connect(userOne).listItemOnAuction1155(0, 100, 10000);

    expect(await jedi1155.balanceOf(userOne.address, 0)).to.eq(0);

    await jedi20.mint(userOne.address, 11000);
    await jedi20.connect(userOne).approve(jediMarket.address, 11000);
    await jediMarket.connect(userOne).makeBid1155(0, 11000);

    expect(await jedi20.balanceOf(userOne.address)).to.eq(0);
    expect(await jedi20.balanceOf(jediMarket.address)).to.eq(11000);

    await jedi20.mint(userTwo.address, 15000);
    await jedi20.connect(userTwo).approve(jediMarket.address, 15000);
    await jediMarket.connect(userTwo).makeBid1155(0, 15000);

    expect(await jedi20.balanceOf(userTwo.address)).to.eq(0);
    expect(await jedi20.balanceOf(userOne.address)).to.eq(11000);
    expect(await jedi20.balanceOf(jediMarket.address)).to.eq(15000);

    expect(jediMarket.connect(userOne).finishAuction1155(0)).to.be.revertedWith(
      "Auction not finished"
    );
    expect(jediMarket.connect(userTwo).finishAuction1155(0)).to.be.revertedWith(
      "You are not owner"
    );
  });

  it("should be able to list and finish correct", async function () {
    await jediMarket.connect(userOne).createItem1155(100);

    await jedi1155.connect(userOne).setApprovalForAll(jediMarket.address, true);
    await jediMarket.connect(userOne).listItemOnAuction1155(0, 100, 10000);

    await jedi20.mint(userOne.address, 11000);
    await jedi20.connect(userOne).approve(jediMarket.address, 11000);
    await jediMarket.connect(userOne).makeBid1155(0, 11000);

    await jedi20.mint(userTwo.address, 15000);
    await jedi20.connect(userTwo).approve(jediMarket.address, 15000);
    await jediMarket.connect(userTwo).makeBid1155(0, 15000);

    await jedi20.mint(userThree.address, 20000);
    await jedi20.connect(userThree).approve(jediMarket.address, 20000);
    await jediMarket.connect(userThree).makeBid1155(0, 20000);

    await jediMarket.backDate1155(0);

    expect(jediMarket.connect(userOne).cancelAuction1155(0)).to.be.revertedWith(
      "Bids more than 2"
    );

    expect(await jedi1155.balanceOf(userThree.address, 0)).to.eq(0);
    expect(await jedi1155.balanceOf(jediMarket.address, 0)).to.eq(100);

    await jediMarket.connect(userOne).finishAuction1155(0);

    expect(await jedi1155.balanceOf(userThree.address, 0)).to.eq(100);
    expect(await jedi1155.balanceOf(jediMarket.address, 0)).to.eq(0);
    expect(await jedi20.balanceOf(userOne.address)).to.eq(11000 + 20000);
  });
});
