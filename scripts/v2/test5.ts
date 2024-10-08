import { ethers } from "hardhat";
import { Test20__factory } from "../../typechain-types";

(async () => {
  const [signer] = await ethers.getSigners();

  const test20 = await new Test20__factory(signer).deploy();

  await test20.deployed();

  await test20.counter().then(console.log);

  const incremented = await test20.callStatic.increment();

  console.log(incremented.toString());
})();
