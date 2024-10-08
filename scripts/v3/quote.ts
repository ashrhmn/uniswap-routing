import {
  formatEther,
  formatUnits,
  parseUnits,
  solidityPack,
} from "ethers/lib/utils";
import { ethers } from "hardhat";
import { IQuoterV2, IQuoterV2__factory } from "../../typechain-types";
import { quoterAddress, tokens } from "../addresses";

(async () => {
  const quoter = IQuoterV2__factory.connect(quoterAddress, ethers.provider);

  const params: IQuoterV2.QuoteExactInputSingleParamsStruct = {
    fee: 10000,
    tokenIn: tokens.usdc,
    tokenOut: tokens.dai,
    amountIn: parseUnits("10", 6),
    sqrtPriceLimitX96: 0,
  };
  const outAmountSingle = await quoter.callStatic
    .quoteExactInputSingle(params)
    .then(({ amountOut }) => formatUnits(amountOut, 18));

  console.log("Exact Input Single : ", outAmountSingle);

  const path = solidityPack(
    ["address", "uint24", "address", "uint24", "address"],
    [tokens.ku, 10000, tokens.weth, 3000, tokens.link]
  );
  const outAmountMulti = await quoter.callStatic
    .quoteExactInput(path, parseUnits("1", 6))
    .then(({ amountOut }) => formatEther(amountOut));

  console.log("Exact Input Multi : ", outAmountMulti);
})();
