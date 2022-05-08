/* eslint-disable prefer-const */
// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";
import { Contract } from "ethers";

async function main() {
  let jediMarket: Contract;
  let jedi20: Contract;
  let jedi721: Contract;
  let jedi1155: Contract;

  const Jedi20 = await ethers.getContractFactory("Jedi20");
  jedi20 = <Contract>await Jedi20.deploy("JDT", "JediToken", 10000000, 1);

  await jedi20.deployed();

  console.log("Jedi20 deployed to:", jedi20.address);

  const Jedi721 = await ethers.getContractFactory("Jedi721");
  jedi721 = <Contract>await Jedi721.deploy();

  await jedi721.deployed();

  console.log("Jedi721 deployed to:", jedi721.address);

  const Jedi1155 = await ethers.getContractFactory("Jedi1155");
  jedi1155 = <Contract>await Jedi1155.deploy();

  await jedi1155.deployed();

  console.log("Jedi1155 deployed to:", jedi1155.address);

  const JediMarketPlace = await ethers.getContractFactory("JediMarketPlace");
  jediMarket = <Contract>(
    await JediMarketPlace.deploy(
      jedi20.address,
      jedi721.address,
      jedi1155.address
    )
  );

  await jediMarket.deployed();

  console.log("JediMarketPlace deployed to:", jediMarket.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
