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
    // Add code below to MarketPlace contract for testing
    // function backDate(uint256 id) external {
    //     _auctionItems[id].startDate -= 3 days;
    // }

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

  it("should be deployed", async function () {
    expect(jediMarket.address).to.be.properAddress;
  });

  it("should be able to mint and get totalSupply on Jedi721", async function () {
    await jediMarket
      .connect(userOne)
      .createItem("Qma8z6G3c1gsKUcfv8JqoEtFMsrq5hBuESp3EiB8juXiS9");
    const firstSupply = await jedi721.totalSupply();

    await jediMarket
      .connect(userTwo)
      .createItem("QmSH4vX1LbnA5iSvTAWxkbewFtsAWintstEQiXVuPj11cv");
    const secondSupply = await jedi721.totalSupply();

    expect(firstSupply).to.eq(1);
    expect(secondSupply).to.eq(2);
  });

  it("should be able to list and buy", async function () {
    await jediMarket
      .connect(userOne)
      .createItem("Qma8z6G3c1gsKUcfv8JqoEtFMsrq5hBuESp3EiB8juXiS9");

    await jedi721.connect(userOne).approve(jediMarket.address, 0);
    await jediMarket.connect(userOne).listItem(0, 10);

    await jedi20.mint(userTwo.address, 10);
    await jedi20.connect(userTwo).approve(jediMarket.address, 10);
    await jediMarket.connect(userTwo).buyItem(0);

    expect(await jedi721.balanceOf(userTwo.address)).to.eq(1);
  });

  it("should be able to list and cancel", async function () {
    await jediMarket
      .connect(userOne)
      .createItem("Qma8z6G3c1gsKUcfv8JqoEtFMsrq5hBuESp3EiB8juXiS9");

    expect(await jedi721.balanceOf(userOne.address)).to.eq(1);

    await jedi721.connect(userOne).approve(jediMarket.address, 0);
    await jediMarket.connect(userOne).listItem(0, 10);

    expect(await jedi721.balanceOf(userOne.address)).to.eq(0);

    await jediMarket.connect(userOne).cancel(0);

    expect(await jedi721.balanceOf(userOne.address)).to.eq(1);
  });

  it("should be able to list on auction and cancel", async function () {
    await jediMarket
      .connect(userOne)
      .createItem("Qma8z6G3c1gsKUcfv8JqoEtFMsrq5hBuESp3EiB8juXiS9");

    expect(await jedi721.balanceOf(userOne.address)).to.eq(1);

    await jedi721.connect(userOne).approve(jediMarket.address, 0);
    await jediMarket.connect(userOne).listItemOnAuction(0, 10000);

    expect(await jedi721.balanceOf(userOne.address)).to.eq(0);

    await jedi20.mint(userOne.address, 11000);
    await jedi20.connect(userOne).approve(jediMarket.address, 11000);
    await jediMarket.connect(userOne).makeBid(0, 11000);

    expect(await jedi20.balanceOf(userOne.address)).to.eq(0);
    expect(await jedi20.balanceOf(jediMarket.address)).to.eq(11000);

    await jedi20.mint(userTwo.address, 15000);
    await jedi20.connect(userTwo).approve(jediMarket.address, 15000);
    await jediMarket.connect(userTwo).makeBid(0, 15000);

    expect(await jedi20.balanceOf(userTwo.address)).to.eq(0);
    expect(await jedi20.balanceOf(userOne.address)).to.eq(11000);
    expect(await jedi20.balanceOf(jediMarket.address)).to.eq(15000);

    await jediMarket.backDate(0);

    expect(jediMarket.connect(userOne).finishAuction(0)).to.be.revertedWith(
      "Bids less than 2"
    );

    await jediMarket.connect(userOne).cancelAuction(0);

    expect(await jedi20.balanceOf(userTwo.address)).to.eq(15000);
    expect(await jedi721.balanceOf(userOne.address)).to.eq(1);
  });

  it("should be able to list and not finish early", async function () {
    await jediMarket
      .connect(userOne)
      .createItem("Qma8z6G3c1gsKUcfv8JqoEtFMsrq5hBuESp3EiB8juXiS9");

    await jedi721.connect(userOne).approve(jediMarket.address, 0);
    await jediMarket.connect(userOne).listItemOnAuction(0, 10000);

    expect(await jedi721.balanceOf(userOne.address)).to.eq(0);

    await jedi20.mint(userOne.address, 11000);
    await jedi20.connect(userOne).approve(jediMarket.address, 11000);
    await jediMarket.connect(userOne).makeBid(0, 11000);

    expect(await jedi20.balanceOf(userOne.address)).to.eq(0);
    expect(await jedi20.balanceOf(jediMarket.address)).to.eq(11000);

    await jedi20.mint(userTwo.address, 15000);
    await jedi20.connect(userTwo).approve(jediMarket.address, 15000);
    await jediMarket.connect(userTwo).makeBid(0, 15000);

    expect(await jedi20.balanceOf(userTwo.address)).to.eq(0);
    expect(await jedi20.balanceOf(userOne.address)).to.eq(11000);
    expect(await jedi20.balanceOf(jediMarket.address)).to.eq(15000);

    expect(jediMarket.connect(userOne).finishAuction(0)).to.be.revertedWith(
      "Auction not finished"
    );
    expect(jediMarket.connect(userTwo).finishAuction(0)).to.be.revertedWith(
      "You are not owner"
    );
  });

  it("should be able to list and finish correct", async function () {
    await jediMarket
      .connect(userOne)
      .createItem("Qma8z6G3c1gsKUcfv8JqoEtFMsrq5hBuESp3EiB8juXiS9");

    await jedi721.connect(userOne).approve(jediMarket.address, 0);
    await jediMarket.connect(userOne).listItemOnAuction(0, 10000);

    await jedi20.mint(userOne.address, 11000);
    await jedi20.connect(userOne).approve(jediMarket.address, 11000);
    await jediMarket.connect(userOne).makeBid(0, 11000);

    await jedi20.mint(userTwo.address, 15000);
    await jedi20.connect(userTwo).approve(jediMarket.address, 15000);
    await jediMarket.connect(userTwo).makeBid(0, 15000);

    await jedi20.mint(userThree.address, 20000);
    await jedi20.connect(userThree).approve(jediMarket.address, 20000);
    await jediMarket.connect(userThree).makeBid(0, 20000);

    await jediMarket.backDate(0);

    expect(jediMarket.connect(userOne).cancelAuction(0)).to.be.revertedWith(
      "Bids more than 2"
    );

    expect(await jedi721.balanceOf(userThree.address)).to.eq(0);
    expect(await jedi721.balanceOf(jediMarket.address)).to.eq(1);

    await jediMarket.connect(userOne).finishAuction(0);

    expect(await jedi721.balanceOf(userThree.address)).to.eq(1);
    expect(await jedi721.balanceOf(jediMarket.address)).to.eq(0);
    expect(await jedi20.balanceOf(userOne.address)).to.eq(11000 + 20000);
  });
});
