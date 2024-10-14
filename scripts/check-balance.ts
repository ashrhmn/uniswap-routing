import { ethers } from "hardhat";
import { ERC20__factory } from "../typechain-types";
import { formatUnits } from "ethers/lib/utils";
import { tokens } from "./addresses";

const tokenAddress = tokens.usdc;

(async () => {
  const [signer] = await ethers.getSigners();
  const token = ERC20__factory.connect(tokenAddress, ethers.provider);
  const decimals = await token.decimals();
  const balance = await token.balanceOf(signer.address);
  console.log(formatUnits(balance, decimals));
})();
