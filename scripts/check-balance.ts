import { ethers } from "hardhat";
import { ERC20__factory } from "../typechain-types";
import { formatUnits } from "ethers/lib/utils";
import { tokens } from "./addresses";

const tokenAddress = "0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2";

(async () => {
  const [signer] = await ethers.getSigners();
  const token = ERC20__factory.connect(tokenAddress, ethers.provider);
  const decimals = await token.decimals();
  const balance = await token.balanceOf(signer.address);
  console.log(formatUnits(balance, decimals));
})();
