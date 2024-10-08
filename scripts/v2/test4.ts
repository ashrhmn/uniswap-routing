import { ethers } from "hardhat";

(async () => {
  const hash =
    "0x297350bde5be8093e20d8265844fcdf1ac895a65f9c9d8af5e911e59c41a1cb8";
  const provider = ethers.provider;

  const tx = await provider.getTransaction(hash);

  console.log(tx);
})();
