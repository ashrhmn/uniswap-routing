import { parseEther, solidityPack } from "ethers/lib/utils";
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

  const stg = ERC20__factory.connect(tokens.stg, signer);

  await stg
    .approve(swap.address, ethers.constants.MaxUint256)
    .then((tx) => tx.wait());

  await debugBalance({ signer, owner, swap }, [tokens.weth, tokens.stg], true);

  const path = solidityPack(
    ["address", "uint24", "address", "uint24", "address"],
    [
      "0xAf5191B0De278C7286d6C7CC6ab6BB8A73bA2Cd6",
      10000,
      "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
      500,
      "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
    ]
  );

  const amountIn = parseEther("7000");
  const tx = await swap.swapExactInputMultihop({
    deadline: getDeadline(),
    path,
    tokenIn: tokens.stg,
    tokenOut: tokens.weth,
    amountIn,
    amountOutMinimum: 0,
    owner: owner.address,
    ownerFee: 10000,
  });
  console.log(tx.hash);
  await tx.wait();

  await debugBalance({ signer, owner, swap }, [tokens.weth, tokens.stg], true);
  process.exit(0);
})();
