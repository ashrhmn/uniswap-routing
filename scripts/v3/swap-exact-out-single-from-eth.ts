import { parseUnits } from "ethers/lib/utils";
import { ethers } from "hardhat";
import { Swap__factory } from "../../typechain-types";
import { swapRouter, tokens } from "../addresses";
import { debugBalance, getDeadline } from "../utils";

(async () => {
  const [signer, owner] = await ethers.getSigners();
  const swap = await new Swap__factory(signer).deploy(swapRouter, tokens.weth);
  await swap.deployed();
  console.log(swap.address);
  // await swap.setOwner(owner.address).then((tx) => tx.wait());

  await debugBalance({ signer, owner, swap }, [tokens.usdc, tokens.weth], true);

  console.log("Approved");
  const amountIn = parseUnits("1000", 18);

  const tx = await swap.swapExactOutputSingle(
    {
      tokenIn: tokens.weth,
      tokenOut: tokens.usdc,
      fee: 500,
      deadline: getDeadline(),
      sqrtPriceLimitX96: 0,
      amountOut: parseUnits("1000", 6),
      amountInMaximum: amountIn,
      owner: owner.address,
      ownerFee: 10000,
    },
    { value: amountIn }
  );
  console.log(tx.hash);
  await tx.wait();

  await debugBalance({ signer, owner, swap }, [tokens.usdc, tokens.weth], true);
  process.exit(0);
})();
