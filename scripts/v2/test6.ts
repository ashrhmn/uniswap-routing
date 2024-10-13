import { ethers } from "hardhat";
import { IERC20__factory, Swap__factory } from "../../typechain-types";
import { swapRouter, swapRouterV2, tokens } from "../addresses";
import { debugBalance, getDeadline } from "../utils";
import { parseUnits } from "ethers/lib/utils";

(async () => {
  const [signer, owner] = await ethers.getSigners();
  const swap = await new Swap__factory(signer).deploy(
    swapRouter,
    swapRouterV2,
    tokens.weth
  );
  console.log(swap.address);

  await swap.deployed();

  console.log("Deployed");

  const debug = () =>
    debugBalance(
      { signer },
      [tokens.usdc, "0xcf0c122c6b73ff809c693db761e7baebe62b6a2e"],
      true
    );
  await debug();
  const path = [
    "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
    "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
    "0xcf0C122c6b73ff809C693DB761e7BaeBe62b6a2E",
  ];

  await IERC20__factory.connect(tokens.usdc, signer)
    .approve(swap.address, ethers.constants.MaxUint256)
    .then((tx) => tx.wait());

  const tx = await swap.swapExactTokensForTokensV2({
    path,
    amountOutMin: parseUnits("10", 9),
    amountIn: parseUnits("10", 6),
    owner: owner.address,
    ownerFee: 10000,
    deadline: getDeadline(),
  });
  await tx.wait();
  await debug();
})();
