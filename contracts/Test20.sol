// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/external/IWETH9.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract Test20 is ERC20 {
    constructor() ERC20("", "") {}

    uint256 public counter = 0;

    function increment() external returns (uint256) {
        uint256 i = ++counter;
        return i;
    }

    function test() external view returns (uint256) {
        uint256 t = totalSupply();
        return t;
    }
}
