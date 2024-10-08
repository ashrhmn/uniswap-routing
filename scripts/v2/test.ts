import { parseUnits } from "ethers/lib/utils";
import { ethers } from "hardhat";
import { ERC20__factory, SwapV2__factory } from "../../typechain-types";
import { swapRouterV2, tokens } from "../addresses";
import { debugBalance, getDeadline } from "../utils";

(async () => {
  const [signer] = await ethers.getSigners();
  const swap = await new SwapV2__factory(signer).deploy(swapRouterV2);
  await swap.deployed();

  const debug = () =>
    debugBalance({ signer, swap }, [tokens.usdc, tokens.wise], true);

  const usdc = ERC20__factory.connect(tokens.usdc, signer);
  const usdcDecimals = await usdc.decimals();
  await usdc
    .approve(swap.address, parseUnits("2000", usdcDecimals))
    .then((tx) => tx.wait());
  await debug();
  const tx = await swap.swapExactTokensForTokens(
    parseUnits("1", usdcDecimals),
    parseUnits("4", 18),
    [tokens.usdc, tokens.weth, tokens.wise],
    signer.address,
    getDeadline()
  );
  await tx.wait();
  await debug();
})();
