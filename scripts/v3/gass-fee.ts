import { parseEther } from "ethers/lib/utils";
import { ethers } from "hardhat";

(async () => {
  const provider = ethers.provider;
  const [user1, user2] = await ethers.getSigners();
  const { maxFeePerGas, maxPriorityFeePerGas } = await provider.getFeeData();
  if (!maxFeePerGas || !maxPriorityFeePerGas)
    throw new Error("No fee data available");

  // Sample transaction sending 1 ETH to user 2 from user 1
  const tx = await user1.sendTransaction({
    value: parseEther("1"),
    to: user2.address,
    maxFeePerGas, // Specifying the max fee/gas price
    maxPriorityFeePerGas, // Specifying the max priority fee/gas price with mining tip included
  });
  await tx.wait();
})();
