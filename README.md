# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.ts
```


--- node 18 is recommended ---

--- compile the project --- 
pnpm hardhat compile 


--- run the node in mainnet ----
pnpm hardhat node --fork https://mainnet.infura.io/v3/3b85ec3ca06a42fca92058a126019eab


--- routing script finds the routing and write in pool.json file ---
pnpm hardhat run ./scripts/routin
g.ts  --network mainnet

--- swap exact in single (loads the ku token) ---
npm hardhat run ./scripts/swap-exact-in-single.ts  --network localhost

--- swap exact in multi (then we can swap the token in multi)---
npm hardhat run ./scripts/swap-exact-in-multi.ts  --network localhost