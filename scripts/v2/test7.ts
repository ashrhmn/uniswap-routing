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
    debugBalance({ signer, owner, swap }, [tokens.usdc, tokens.wise], true);
  await debug();
  const path = [tokens.usdc, tokens.weth, tokens.wise];

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
