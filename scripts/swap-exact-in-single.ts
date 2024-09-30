import {
  formatEther,
  formatUnits,
  parseEther,
  parseUnits,
} from "ethers/lib/utils";
import { ethers } from "hardhat";
import {
  ERC20__factory,
  IWETH9__factory,
  Swap__factory,
} from "../typechain-types";
import { swapRouter, tokens } from "./addresses";

(async () => {
  const provider = ethers.provider;
  const [signer, owner] = await ethers.getSigners();
  const swap = await new Swap__factory(signer).deploy(swapRouter, tokens.weth);
  await swap.deployed();
  console.log(swap.address);
  await swap.setOwner(owner.address).then((tx) => tx.wait());
  const weth = IWETH9__factory.connect(tokens.weth, signer);
  // await weth
  //   .deposit({ value: ethers.utils.parseEther("100") })
  //   .then((tx) => tx.wait());

  const ku = ERC20__factory.connect(tokens.ku, signer);
  const decimal = await ku.decimals();

  const debugBalance = async () => {
    await ERC20__factory.connect(tokens.ku, provider)
      .balanceOf(signer.address)
      .then((v) => formatUnits(v, decimal))
      .then(console.log);
    await ERC20__factory.connect(tokens.ku, provider)
      .balanceOf(owner.address)
      .then((v) => formatUnits(v, decimal))
      .then(console.log);
    await ethers.provider
      .getBalance(signer.address)
      .then(formatEther)
      .then(console.log);
    await ethers.provider
      .getBalance(owner.address)
      .then(formatEther)
      .then(console.log);
  };

  await debugBalance();

  await ku
    .approve(swap.address, ethers.constants.MaxUint256)
    .then((tx) => tx.wait());
  console.log("Approved");
  const amountIn = parseUnits("8499", decimal);

  const tx = await swap.swapExactInputSingle(
    {
      tokenIn: tokens.ku,
      tokenOut: tokens.weth,
      amountIn,
      fee: 10000,
      amountOutMinimum: 0,
    },
    { value: amountIn }
  );
  console.log(tx.hash);
  await tx.wait();

  await debugBalance();
  process.exit(0);
})();
