import { Wallet } from "ethers";
import { parseEther } from "ethers/lib/utils";
import { ethers } from "hardhat";

(async () => {
  const provider = new ethers.providers.StaticJsonRpcProvider(
    "https://infura.io/v1/c6e4.....API..KEY........c5a"
  );

  const privateKey = "0x2f37978c25aee93d....................f6f19a4570f26dd3";

  const wallet = new Wallet(privateKey, provider);

  const [signer, signer2] = await ethers.getSigners();

  const rawTransaction = {
    value: parseEther("0.001"),
    to: signer2.address,
  };

  // const { maxFeePerGas, maxPriorityFeePerGas } = await provider.getFeeData();

  const gasEstimated = await wallet.estimateGas(rawTransaction);

  const maxLimit = parseEther("0.01");

  const gasPrice = maxLimit.div(gasEstimated);

  const tx = await wallet.sendTransaction({
    ...rawTransaction,
    maxFeePerGas: gasPrice,
    maxPriorityFeePerGas: gasPrice,
  }); // The transaction is stuck for some reason
  // Replacing the above transaction

  const rec = await provider.getTransactionReceipt(tx.hash);

  const { maxFeePerGas, maxPriorityFeePerGas, nonce } = tx;

  // The following transaction will replace the above stuck transaction
  await wallet.sendTransaction({
    ...rawTransaction,
    maxFeePerGas: maxFeePerGas?.mul(120).div(100), // Increasing the gas fee by 20% from the stuck transaction
    maxPriorityFeePerGas: maxPriorityFeePerGas?.mul(120).div(100), // Increasing the priority fee by 20% from the stuck transaction
    nonce, // Using the same nonce, so it replace the stuck transaction with the same nonce
  });

  // The following transaction will replace the above stuck transaction
  await wallet.sendTransaction({
    to: wallet.address, // Sending to self address
    value: 0, // Sending 0 ETH
    maxFeePerGas: maxFeePerGas?.mul(120).div(100), // Increasing the gas fee by 20% from the stuck transaction
    maxPriorityFeePerGas: maxPriorityFeePerGas?.mul(120).div(100), // Increasing the priority fee by 20% from the stuck transaction
    nonce, // Using the same nonce, so it replace the stuck transaction with the same nonce
  });
})();
