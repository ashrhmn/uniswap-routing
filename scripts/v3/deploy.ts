import { ethers } from "hardhat";
import { Swap__factory } from "../../typechain-types";
import { swapRouter, tokens } from "../addresses";

(async () => {
  const [signer] = await ethers.getSigners();

  const swap = await new Swap__factory(signer).deploy(swapRouter, tokens.weth);

  console.log(swap.address);

  await swap.deployed();

  console.log("Deployed");

  // await swap.setOwner(owner.address).then((tx) => tx.wait());

  // const weth = IWETH9__factory.connect(tokens.weth, signer);

  // await weth.deposit({ value: parseEther("100") }).then((tx) => tx.wait());
})();
