import { ethers } from "hardhat";
import { IUniswapV2Router02__factory } from "../../typechain-types";
import { swapRouterV2, tokens } from "../addresses";
import { formatUnits, parseUnits } from "ethers/lib/utils";

(async () => {
  const swapRouter = IUniswapV2Router02__factory.connect(
    swapRouterV2,
    ethers.provider
  );

  swapRouter
    .getAmountsOut(parseUnits("1", 18), [tokens.weth, tokens.usdc])
    .then((res) => formatUnits(res[res.length - 1], 6))
    .then(console.log);

  swapRouter
    .getAmountsOut(parseUnits("100", 6), [
      tokens.usdc,
      tokens.weth,
      tokens.wise,
    ])
    .then((res) => formatUnits(res[res.length - 1], 18))
    .then(console.log);
})();
