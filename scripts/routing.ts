import {
  Currency,
  CurrencyAmount,
  NativeCurrency,
  Token,
  TradeType,
} from "@uniswap/sdk-core";
import { AlphaRouter } from "@uniswap/smart-order-router";
import { parseEther } from "ethers/lib/utils";
import { writeFile } from "fs/promises";
import { ethers } from "hardhat";
import { join } from "path";
import { tokens } from "./tokens";

export class NativeToken extends NativeCurrency {
  constructor(
    chainId: number,
    decimals: number,
    symbol: string,
    name: string,
    private readonly wrappedTokenAddress: string
  ) {
    super(chainId, decimals, symbol, name);
  }
  equals(other: Currency): boolean {
    return other.isNative && other.chainId === this.chainId;
  }
  get wrapped(): Token {
    return new Token(this.chainId, this.wrappedTokenAddress, 18);
  }
}

(async () => {
  // const p = new ethers.providers.StaticJsonRpcProvider(
  //   "https://eth-mainnet.alchemyapi.io/v2/your-api-key"
  // );
  const provider = ethers.provider;
  // provider.on("debug", ({ request, response, action }) => {
  //   console.debug(
  //     "On Provider Debug",
  //     JSON.stringify({ action, request, response }, null, 2)
  //   );
  // });
  const chainId = await provider.getNetwork().then(({ chainId }) => chainId);
  const router = new AlphaRouter({
    chainId,
    provider,
  });
  const tokenIn = new Token(chainId, tokens.ku, 18);
  // const tokenIn = new NativeToken(chainId, 18, "ETH", "Ether", weth);
  const tokenOut = new Token(chainId, tokens.link, 18);
  const amount = CurrencyAmount.fromRawAmount(
    tokenIn,
    parseEther("100").toString()
  );

  const route = await router.route(amount, tokenOut, TradeType.EXACT_INPUT);

  const poolData = route?.trade.routes
    .filter((r) => r.protocol === "V3")
    .map((r) =>
      r.pools.map(
        ({
          token0: { address: token0 },
          token1: { address: token1 },
          fee,
        }: any) => ({
          token0: token0 as string,
          token1: token1 as string,
          fee: fee as number,
        })
      )
    );

  await writeFile(
    join(__dirname, "pool.json"),
    JSON.stringify(poolData, null, 2)
  );

  process.exit(0);
})();
