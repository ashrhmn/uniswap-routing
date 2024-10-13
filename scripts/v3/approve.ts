import { ethers } from "hardhat";
import { tokens } from "../addresses";
import { MaxUint256 } from "@uniswap/sdk-core";
import { IWETH9__factory } from "../../typechain-types";

const swapAddress = "0x8659DF1C638CDA8E475CD3C6481730C2b4f85873";

(async () => {
  const [signer] = await ethers.getSigners();
  const weth = IWETH9__factory.connect(tokens.usdc, signer);
  await weth
    .approve(swapAddress, MaxUint256.toString())
    .then((tx) => tx.wait());
})();
