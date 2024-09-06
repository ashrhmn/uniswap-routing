import { ethers } from "hardhat";
import { IQuoterV2, IQuoterV2__factory } from "../typechain-types";
import { quoterAddress, tokens } from "./addresses";
import { formatEther, parseEther, solidityPack } from "ethers/lib/utils";

(async () => {
  const quoter = IQuoterV2__factory.connect(quoterAddress, ethers.provider);

  const params: IQuoterV2.QuoteExactInputSingleParamsStruct = {
    fee: 10000,
    tokenIn: tokens.weth,
    tokenOut: tokens.ku,
    amountIn: parseEther("1"),
    sqrtPriceLimitX96: 0,
  };
  const outAmountSingle = await quoter.callStatic
    .quoteExactInputSingle(params)
    .then(({ amountOut }) => formatEther(amountOut));

  console.log("Exact Input Single : ", outAmountSingle);

  const path = solidityPack(
    ["address", "uint24", "address", "uint24", "address"],
    [tokens.ku, 10000, tokens.weth, 3000, tokens.link]
  );
  const outAmountMulti = await quoter.callStatic
    .quoteExactInput(path, parseEther("1"))
    .then(({ amountOut }) => formatEther(amountOut));

  console.log("Exact Input Multi : ", outAmountMulti);
})();
