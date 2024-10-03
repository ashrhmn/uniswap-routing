import { ethers } from "hardhat";
import { IWETH9__factory } from "../typechain-types";
import { tokens } from "./addresses";
import { MaxUint256 } from "@uniswap/sdk-core";

const swapAddress = "0x81ED8e0325B17A266B2aF225570679cfd635d0bb";

(async () => {
  const [signer] = await ethers.getSigners();
  const weth = IWETH9__factory.connect(tokens.usdc, signer);
  await weth
    .approve(swapAddress, MaxUint256.toString())
    .then((tx) => tx.wait());
})();
