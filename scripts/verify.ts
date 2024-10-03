import * as hre from "hardhat";
import { swapRouter, tokens } from "./addresses";

hre
  .run("verify:verify", {
    address: "0xB97c2804f6770314C01F91Fbbf2041622C032d42",
    constructorArguments: [swapRouter, tokens.weth],
  })
  .then(console.log)
  .catch(console.error);
