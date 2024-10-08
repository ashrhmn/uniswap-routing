import { parseEther, solidityPack } from "ethers/lib/utils";
import { ethers } from "hardhat";
import { Swap__factory } from "../../typechain-types";
import { swapRouter, tokens } from "../addresses";
import { debugBalance, getDeadline } from "../utils";

(async () => {
  const [signer, owner] = await ethers.getSigners();
  const swap = await new Swap__factory(signer).deploy(swapRouter, tokens.weth);
  await swap.deployed();
  console.log(swap.address);

  await debugBalance({ signer, owner, swap }, [tokens.weth, tokens.stg], true);

  const path = solidityPack(
    ["address", "uint24", "address", "uint24", "address"],
    [
      "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
      500,
      "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
      10000,
      "0xAf5191B0De278C7286d6C7CC6ab6BB8A73bA2Cd6",
    ]
  );

  const amountIn = parseEther("1");
  const tx = await swap.swapExactInputMultihop(
    {
      deadline: getDeadline(),
      path,
      tokenIn: tokens.weth,
      tokenOut: tokens.stg,
      amountIn,
      amountOutMinimum: 0,
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
