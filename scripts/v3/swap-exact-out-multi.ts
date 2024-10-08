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

  await debugBalance({ signer, owner, swap }, [tokens.frax, tokens.ku]);

  const path = solidityPack(
    ["address", "uint24", "address", "uint24", "address", "uint24", "address"],
    [
      "0x853d955aCEf822Db058eb8505911ED77F175b99e",
      500,
      "0x6B175474E89094C44Da98b954EedeAC495271d0F",
      3000,
      "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
      10000,
      "0xf34960d9d60be18cC1D5Afc1A6F012A723a28811",
    ]
  );

  const frax = ERC20__factory.connect(tokens.frax, signer);

  await frax
    .approve(swap.address, ethers.constants.MaxUint256)
    .then((tx) => tx.wait());

  const amountIn = parseEther("100");
  const tx = await swap.swapExactOutputMultihop({
    deadline: getDeadline(),
    path,
    tokenIn: tokens.frax,
    tokenOut: tokens.ku,
    amountInMaximum: amountIn,
    amountOut: parseEther("1"),
    owner: owner.address,
    ownerFee: 10000,
  });
  console.log(tx.hash);
  await tx.wait();

  await debugBalance({ signer, owner, swap }, [tokens.frax, tokens.ku]);
  process.exit(0);
})();
