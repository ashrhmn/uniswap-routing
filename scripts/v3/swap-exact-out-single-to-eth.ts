import { parseUnits } from "ethers/lib/utils";
import { ethers } from "hardhat";
import { ERC20__factory, Swap__factory } from "../../typechain-types";
import { swapRouter, tokens } from "../addresses";
import { debugBalance, getDeadline } from "../utils";

(async () => {
  const [signer, owner] = await ethers.getSigners();
  const swap = await new Swap__factory(signer).deploy(swapRouter, tokens.weth);
  await swap.deployed();
  console.log(swap.address);
  // await swap.setOwner(owner.address).then((tx) => tx.wait());

  const usdc = ERC20__factory.connect(tokens.usdc, signer);
  const decimal = await usdc.decimals();

  await debugBalance({ signer, owner, swap }, [tokens.usdc, tokens.weth], true);

  await usdc
    .approve(swap.address, ethers.constants.MaxUint256)
    .then((tx) => tx.wait());
  console.log("Approved");

  // const usdcBalance = await usdc.balanceOf(signer.address);
  const amountInMaximum = parseUnits("10000", decimal);

  const tx = await swap.swapExactOutputSingle({
    tokenIn: tokens.usdc,
    tokenOut: tokens.weth,
    fee: 500,
    deadline: getDeadline(),
    sqrtPriceLimitX96: 0,
    amountOut: parseUnits("1", 18),
    amountInMaximum,
    owner: owner.address,
    ownerFee: 10000,
  });
  console.log(tx.hash);
  await tx.wait();

  await debugBalance({ signer, owner, swap }, [tokens.usdc, tokens.weth], true);
  process.exit(0);
})();
