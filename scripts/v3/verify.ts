import * as hre from "hardhat";
import { swapRouter, swapRouterV2, tokens } from "../addresses";

hre
  .run("verify:verify", {
    address: "0x14E1a4B95a860c346f50b43c2d62baEDac32600c",
    constructorArguments: [
      "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45",
      "0xedf6066a2b290C185783862C7F4776A2C8077AD1",
      "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270",
    ],
  })
  .then(console.log)
  .catch(console.error);
