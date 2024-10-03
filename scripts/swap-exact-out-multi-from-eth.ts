import { parseEther, solidityPack } from "ethers/lib/utils";
import { ethers } from "hardhat";
import { Swap__factory } from "../typechain-types";
import { swapRouter, tokens } from "./addresses";
import { debugBalance, getDeadline } from "./utils";

(async () => {
  const [signer, owner] = await ethers.getSigners();
  const swap = await new Swap__factory(signer).deploy(swapRouter, tokens.weth);
  await swap.deployed();
  console.log(swap.address);
  // await swap.setOwner(owner.address).then((tx) => tx.wait());

  await debugBalance({ signer, owner, swap }, [tokens.weth, tokens.stg], true);

  const path = solidityPack(
    ["address", "uint24", "address", "uint24", "address"],
    [tokens.weth, 500, tokens.usdc, 500, tokens.frax]
  );

  const amountIn = parseEther("100");
  const tx = await swap.swapExactOutputMultihop(
    {
      deadline: getDeadline(),
      path,
      tokenIn: tokens.weth,
      tokenOut: tokens.frax,
      amountInMaximum: amountIn,
      amountOut: parseEther("1"),
      owner: owner.address,
      ownerFee: 10000,
    },
    { value: amountIn }
  );
  console.log(tx.hash);
  await tx.wait();

  await debugBalance({ signer, owner, swap }, [tokens.weth, tokens.stg], true);
  process.exit(0);
})();
