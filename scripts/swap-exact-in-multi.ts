import { formatEther, solidityPack } from "ethers/lib/utils";
import { ethers } from "hardhat";
import {
  ERC20__factory,
  IWETH9__factory,
  Swap__factory,
} from "../typechain-types";
import { swapRouter, tokens } from "./tokens";

(async () => {
  const provider = ethers.provider;
  const [signer, owner] = await ethers.getSigners();
  const swap = await new Swap__factory(signer).deploy(swapRouter);
  await swap.deployed();
  console.log(swap.address);
  await swap.setOwner(owner.address).then((tx) => tx.wait());
  const weth = IWETH9__factory.connect(tokens.weth, signer);
  await weth
    .deposit({ value: ethers.utils.parseEther("100") })
    .then((tx) => tx.wait());

  const debugBalance = async () => {
    await ERC20__factory.connect(tokens.link, provider)
      .balanceOf(signer.address)
      .then(formatEther)
      .then(console.log);
    await ERC20__factory.connect(tokens.link, provider)
      .balanceOf(owner.address)
      .then(formatEther)
      .then(console.log);
  };

  await debugBalance();

  await ERC20__factory.connect(tokens.ku, signer)
    .approve(swap.address, ethers.constants.MaxUint256)
    .then((tx) => tx.wait());
  console.log("Approved");

  const path = solidityPack(
    ["address", "uint24", "address", "uint24", "address"],
    [tokens.ku, 10000, tokens.weth, 3000, tokens.link]
  );

  const balance = await ERC20__factory.connect(tokens.ku, provider).balanceOf(
    signer.address
  );

  const tx = await swap.swapExactInputMultihop(
    balance,
    tokens.ku,
    tokens.link,
    path
  );
  console.log(tx.hash);
  await tx.wait();

  await debugBalance();
  process.exit(0);
})();
