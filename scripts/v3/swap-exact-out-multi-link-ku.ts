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

  await debugBalance({ signer, owner, swap }, [tokens.link, tokens.ku]);

  const path = solidityPack(
    ["address", "uint24", "address", "uint24", "address"],
    [tokens.link, 3000, tokens.weth, 10000, tokens.ku]
  );

  const link = ERC20__factory.connect(tokens.link, signer);

  await link
    .approve(swap.address, ethers.constants.MaxUint256)
    .then((tx) => tx.wait());

  const amountIn = parseEther("100");
  const tx = await swap.swapExactOutputMultihop({
    deadline: getDeadline(),
    path,
    tokenIn: tokens.link,
    tokenOut: tokens.ku,
    amountInMaximum: amountIn,
    amountOut: parseEther("1"),
    owner: owner.address,
    ownerFee: 10000,
  });
  console.log(tx.hash);
  await tx.wait();

  await debugBalance({ signer, owner, swap }, [tokens.link, tokens.ku]);
  process.exit(0);
})();
