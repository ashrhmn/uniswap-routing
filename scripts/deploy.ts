import { ethers } from "hardhat";
import { IWETH9__factory, Swap__factory } from "../typechain-types";
import { swapRouter, tokens } from "./addresses";
import { parseEther } from "ethers/lib/utils";

(async () => {
  const [signer, owner] = await ethers.getSigners();

  const swap = await new Swap__factory(signer)
    .deploy(swapRouter)
    .then((c) => c.deployed());

  console.log(swap.address);

  await swap.setOwner(owner.address).then((tx) => tx.wait());

  const weth = IWETH9__factory.connect(tokens.weth, signer);

  await weth.deposit({ value: parseEther("100") }).then((tx) => tx.wait());
})();
