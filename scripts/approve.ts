import { ethers } from "hardhat";
import { IWETH9__factory } from "../typechain-types";
import { tokens } from "./addresses";
import { MaxUint256 } from "@uniswap/sdk-core";

const swapAddress = "0xdccF554708B72d0fe9500cBfc1595cDBE3d66e5a";

(async () => {
  const [signer] = await ethers.getSigners();
  const weth = IWETH9__factory.connect(
    "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
    signer
  );
  await weth
    .approve(swapAddress, MaxUint256.toString())
    .then((tx) => tx.wait());
})();
