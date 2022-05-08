/* eslint-disable prettier/prettier */
/* eslint-disable node/no-unpublished-import */
/* eslint-disable node/no-extraneous-import */
import * as dotenv from "dotenv";

import { task } from "hardhat/config"
import { Contract } from "ethers";
import "@nomiclabs/hardhat-waffle";

dotenv.config();

task("mint1155", "Mint item on ERC1155 with amount")
  .addParam("amount", "Amount of token")
  .setAction(async (taskArgs, hre) => {
    const [signer] = await hre.ethers.getSigners();
    const contractAddr = process.env.CONTRACT_ADDRESS_MARKET;

    const MarketPlaceContract = <Contract>await hre.ethers.getContractAt(
      "JediMarketPlace",
      contractAddr as string,
      signer
    );

    const result = await MarketPlaceContract.creatItem1155(taskArgs.amount);

    console.log(result);
  });
