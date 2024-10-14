import { ethers } from "hardhat";
import { Swap__factory } from "../typechain-types";
import { swapRouter, swapRouterV2, tokens } from "./addresses";

(async () => {
  const [signer] = await ethers.getSigners();

  // const swap = await new Swap__factory(signer).deploy(
  //   "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45",
  //   "0xedf6066a2b290C185783862C7F4776A2C8077AD1",
  //   "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270"
  // );

  const swap = await new Swap__factory(signer).deploy(
    swapRouter,
    swapRouterV2,
    tokens.weth
  );
  console.log(swap.address);

  await swap.deployed();

  console.log("Deployed");

  // await swap.setOwner(owner.address).then((tx) => tx.wait());

  // const weth = IWETH9__factory.connect(tokens.weth, signer);

  // await weth.deposit({ value: parseEther("100") }).then((tx) => tx.wait());
})();
