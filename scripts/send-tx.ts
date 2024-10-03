import { Wallet } from "ethers";
import { ethers } from "hardhat";

(async () => {
  // const wallet = new Wallet("private......");
  // wallet.sendTransaction({ data: "", to: "" });
  const [signer] = await ethers.getSigners();
  const tx = await signer.sendTransaction({
    data: "0xc67ea252000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc200000000000000000000000000000000000000000000000000000004ec759cc00000000000000000000000000000000000000000000000006f05b59d3b2000000000000000000000000000000000000000000000000000000000000000000064",
    to: "0x81ED8e0325B17A266B2aF225570679cfd635d0bb",
  });
  console.log(tx);
  const receipt = await tx.wait();
  console.log(receipt);
})();
