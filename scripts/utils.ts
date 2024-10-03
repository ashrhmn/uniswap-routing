import { formatUnits, isAddress } from "ethers/lib/utils";
import { ethers } from "hardhat";
import { ERC20__factory } from "../typechain-types";

export const getDeadline = () => ~~(Date.now() / 1000) + 100;

export const debugBalance = async (
  wallets: Record<string, string | { address: string }>,
  tokens: string[],
  includeNative = false
) => {
  if (tokens.some((t) => !isAddress(t)))
    throw new Error("Invalid token address");
  const tokenContracts = tokens.map((token) =>
    ERC20__factory.connect(token, ethers.provider)
  );
  const decimalsArr = await Promise.all(
    tokenContracts.map(async (c) => ({ d: await c.decimals(), a: c.address }))
  );
  const decimals = Object.fromEntries(
    decimalsArr.map(({ a, d }) => [a, d] as const)
  );
  const symbolArr = await Promise.all(
    tokenContracts.map(async (c) => ({
      n: await c.symbol().catch(() => c.address),
      a: c.address,
    }))
  );
  const symbols = Object.fromEntries(
    symbolArr.map(({ a, n }) => [a, n] as const)
  );

  console.log("=====================================================");
  for (const [userName, userAddressOrSigner] of Object.entries(wallets)) {
    const userAddress =
      typeof userAddressOrSigner === "string"
        ? userAddressOrSigner
        : userAddressOrSigner.address;
    if (!isAddress(userAddress))
      throw new Error(`Invalid wallet address of ${userName}: ${userAddress}`);
    console.log(`Balance of ${userName}`);
    if (includeNative) {
      const balance = await ethers.provider.getBalance(userAddress);
      const formattedBalance = formatUnits(balance, 18);
      console.log(`ETH\t:\t${formattedBalance}`);
    }
    for (const tokenContract of tokenContracts) {
      const balance = await tokenContract.balanceOf(userAddress);
      const tokenAddress = tokenContract.address;
      const decimal = decimals[tokenAddress];
      const formattedBalance = formatUnits(balance, decimal);
      const symbol = symbols[tokenAddress];
      console.log(`${symbol}\t:\t${formattedBalance}`);
    }
  }
  console.log("=====================================================");
};
