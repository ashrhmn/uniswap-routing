import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.7.6",
  networks: {
    mainnet: {
      url: "https://mainnet.infura.io/v3/3b85ec3ca06a42fca92058a126019eab",
    },
  },
};

export default config;
