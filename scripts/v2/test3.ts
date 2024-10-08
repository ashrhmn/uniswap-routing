import { Wallet } from "ethers";
import { parseEther } from "ethers/lib/utils";
import { ethers } from "hardhat";

(async () => {
  const [signer] = await ethers.getSigners();

  const dest = "0x1280d821dA5D675B4383779FEbcd873a3BAEaAAA";

  const provider = ethers.provider;

  const nonce = await provider.getTransactionCount(signer.address, "latest");

  console.log({ nonce });

  // if (1) return;
  const { maxPriorityFeePerGas, maxFeePerGas } =
    await ethers.provider.getFeeData();

  console.log({
    maxPriorityFeePerGas: maxPriorityFeePerGas?.toString(),
    maxFeePerGas: maxFeePerGas?.toString(),
  });

  // if (1) return;

  const rawTransaction = {
    value: parseEther("0.001"),
    to: dest,
  };

  const estimatedGas = await provider.estimateGas(rawTransaction);

  const limitFee = parseEther("0.01");

  const maxFee = limitFee.div(estimatedGas);

  const tx = await signer.sendTransaction({
    ...rawTransaction,
    maxFeePerGas: maxFee, // store in db
    maxPriorityFeePerGas: maxFee, // store in db
    nonce, // store in db
  });

  console.log("Tx Sent: ", tx.hash);

  const rec = await tx.wait();

  console.log("Tx Mined");

  console.log(rec);
})();
