import { parseEther, parseUnits, solidityPack } from "ethers/lib/utils";
import { ethers } from "hardhat";
import { ERC20__factory, ISwapRouter__factory } from "../typechain-types";
import { swapRouter, tokens } from "./addresses";
import { debugBalance, getDeadline } from "./utils";

(async () => {
  const [signer] = await ethers.getSigners();

  const swap = ISwapRouter__factory.connect(swapRouter, signer);
  await debugBalance({ signer }, [tokens.link, tokens.mkr]);

  const path = solidityPack(
    ["address", "uint24", "address", "uint24", "address"],
    [
      "0x514910771AF9Ca656af840dff83E8264EcF986CA",
      3000,
      "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
      3000,
      "0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2",
    ]
    // [tokens.link, 3000, tokens.weth, 10000, tokens.mkr]
    // [
    //   "0x514910771AF9Ca656af840dff83E8264EcF986CA",
    //   500,
    //   "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
    //   10000,
    //   "0xf34960d9d60be18cC1D5Afc1A6F012A723a28811",
    // ]
  );

  const link = ERC20__factory.connect(tokens.link, signer);
  const mkr = ERC20__factory.connect(tokens.mkr, signer);

  const linkDecimal = await link.decimals();
  const mkrDecimal = await mkr.decimals();

  const linkBalance = await link.balanceOf(signer.address);

  // const amountIn = parseUnits("100", linkDecimal);
  const amountIn = linkBalance.div(2);

  await link
    .approve(swapRouter, ethers.constants.MaxUint256)
    .then((tx) => tx.wait());

  // await link.approve(swapRouter, amountIn).then((tx) => tx.wait());

  console.log("Approved");

  const tx = await swap.exactOutput({
    deadline: getDeadline(),
    path,
    amountInMaximum: amountIn,
    amountOut: parseUnits("5", mkrDecimal),
    // amountOut: parseUnits("1", mkrDecimal),
    recipient: signer.address,
  });
  console.log(tx.hash);
  await tx.wait();

  await debugBalance({ signer }, [tokens.link, tokens.mkr]);
  process.exit(0);
})();
